import "dotenv/config";
import express from "express";
import cors from "cors";
import multer from "multer";
import fetch, { Headers } from "node-fetch";
import path from "path";
import { fileURLToPath } from "url";
import { promises as fs } from "fs";
import admin from "firebase-admin";
import { CloudTasksClient } from "@google-cloud/tasks";

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

// Cloud Tasks 클라이언트 초기화
const tasksClient = new CloudTasksClient();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = process.env.PORT || 5001;
const db = admin.firestore();

const publicDir = path.join(__dirname, "..", "public");
const uploadDir = path.join(publicDir, "uploads");
const resultDir = path.join(publicDir, "results");

// VisionStory API 설정
const VISIONSTORY_API_KEY = process.env.VISIONSTORY_API_KEY || "";
const VISIONSTORY_API_BASE = process.env.VISIONSTORY_API_BASE || "https://openapi.visionstory.ai";

// Cloud Tasks 설정
const GOOGLE_CLOUD_PROJECT = process.env.GOOGLE_CLOUD_PROJECT || "";
const CLOUD_TASKS_LOCATION = process.env.CLOUD_TASKS_LOCATION || "asia-northeast3";
const CLOUD_TASKS_QUEUE = process.env.CLOUD_TASKS_QUEUE || "video-generation-queue";
const WORKER_URL = process.env.WORKER_URL || `http://localhost:${port}`;

const ensureDir = async (dir) => {
  await fs.mkdir(dir, { recursive: true });
};

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const safeName = file.originalname.replace(/\s+/g, "_");
    const timestamp = Date.now();
    cb(null, `${timestamp}_${safeName}`);
  },
});

const upload = multer({
  storage,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB
  },
});

// Base64 인코딩 헬퍼 함수
const encodeBase64 = async (filePath) => {
  const fileBuffer = await fs.readFile(filePath);
  return fileBuffer.toString("base64");
};

// MIME 타입 결정
const getMimeType = (filename) => {
  const ext = path.extname(filename).toLowerCase();
  const mimeTypes = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
    ".heic": "image/heic",
    ".mp3": "audio/mp3",
    ".wav": "audio/wav",
    ".m4a": "audio/m4a",
    ".aac": "audio/aac",
  };
  return mimeTypes[ext] || "application/octet-stream";
};

void ensureDir(uploadDir);
void ensureDir(resultDir);

app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(uploadDir));
app.use("/results", express.static(resultDir));

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    service: "VisionStory AI Talking Head",
    apiConfigured: !!VISIONSTORY_API_KEY,
  });
});

// 비동기 방식: 즉시 jobId 반환 (Cloud Tasks 사용 - 수시간 처리 가능)
app.post(
  "/generate-with-tasks",
  upload.fields([
    { name: "image", maxCount: 1 },
    { name: "audio", maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const image = req.files?.image?.[0];
      const audio = req.files?.audio?.[0];
      const { userId, instructorName, instructorBio } = req.body;

      if (!image || !audio) {
        return res.status(400).json({
          error: "image and audio files are both required.",
        });
      }

      if (!VISIONSTORY_API_KEY) {
        return res.status(500).json({
          error:
            "VisionStory API key is not configured. Please set VISIONSTORY_API_KEY environment variable.",
        });
      }

      // 1. 파일을 영구 저장소에 업로드 (예: Cloud Storage 또는 유지)
      // 현재는 로컬 uploadDir에 저장됨
      const imageUrl = `/uploads/${image.filename}`;
      const audioUrl = `/uploads/${audio.filename}`;

      // 2. Firestore에 작업 생성
      const jobRef = await db.collection("avatarJobs").add({
        userId: userId || "anonymous",
        instructorName: instructorName || "",
        instructorBio: instructorBio || "",
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        progress: {
          currentStep: "pending",
          stepNumber: 0,
          totalSteps: 3,
          message: "작업이 큐에 추가되었습니다",
        },
        videoUrl: null,
        errorMessage: null,
      });

      const jobId = jobRef.id;

      console.log(`[Job ${jobId}] Created new avatar generation job (Cloud Tasks)`);

      // 3. Cloud Task 생성
      const queuePath = tasksClient.queuePath(
        GOOGLE_CLOUD_PROJECT,
        CLOUD_TASKS_LOCATION,
        CLOUD_TASKS_QUEUE
      );

      const task = {
        httpRequest: {
          httpMethod: "POST",
          url: `${WORKER_URL}/worker/process-avatar`,
          headers: {
            "Content-Type": "application/json",
          },
          body: Buffer.from(
            JSON.stringify({
              jobId,
              imagePath: image.path,
              audioPath: audio.path,
              imageFilename: image.originalname,
              audioFilename: audio.originalname,
            })
          ).toString("base64"),
        },
      };

      await tasksClient.createTask({ parent: queuePath, task });

      console.log(`[Job ${jobId}] Cloud Task created`);

      // 4. 즉시 응답 반환 (HTTP 연결 종료)
      res.json({
        success: true,
        jobId: jobId,
        message: "아바타 생성 작업이 큐에 추가되었습니다. 수시간이 소요될 수 있습니다.",
      });
    } catch (error) {
      console.error("Failed to create task:", error);
      res.status(500).json({
        error: "Failed to create task.",
        details: error.message,
      });
    }
  }
);
app.post(
  "/generate-async",
  upload.fields([
    { name: "image", maxCount: 1 },
    { name: "audio", maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const image = req.files?.image?.[0];
      const audio = req.files?.audio?.[0];
      const { userId, instructorName, instructorBio } = req.body;

      if (!image || !audio) {
        return res.status(400).json({
          error: "image and audio files are both required.",
        });
      }

      if (!VISIONSTORY_API_KEY) {
        return res.status(500).json({
          error:
            "VisionStory API key is not configured. Please set VISIONSTORY_API_KEY environment variable.",
        });
      }

      // 1. Firestore에 작업 생성
      const jobRef = await db.collection("avatarJobs").add({
        userId: userId || "anonymous",
        instructorName: instructorName || "",
        instructorBio: instructorBio || "",
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        progress: {
          currentStep: "pending",
          stepNumber: 0,
          totalSteps: 3,
          message: "작업 대기 중",
        },
        videoUrl: null,
        errorMessage: null,
      });

      const jobId = jobRef.id;

      console.log(`[Job ${jobId}] Created new avatar generation job`);

      // 2. 즉시 응답 반환
      res.json({
        success: true,
        jobId: jobId,
        message: "아바타 생성 작업이 시작되었습니다",
      });

      // 3. 백그라운드에서 비디오 생성 (비동기)
      processAvatarGeneration(jobId, image, audio).catch((error) => {
        console.error(`[Job ${jobId}] Background processing failed:`, error);
      });
    } catch (error) {
      console.error("Failed to create job:", error);
      res.status(500).json({
        error: "Failed to create job.",
        details: error.message,
      });
    }
  }
);

// 백그라운드 비디오 생성 함수
async function processAvatarGeneration(jobId, image, audio) {
  console.log(`[Job ${jobId}] Starting background processing`);

  try {
    // Step 1: 아바타 생성
    await updateJobProgress(jobId, {
      status: "processing",
      progress: {
        currentStep: "avatar_creation",
        stepNumber: 1,
        totalSteps: 3,
        message: "아바타 이미지 업로드 중...",
      },
    });

    console.log(`[Job ${jobId}] Step 1: Creating avatar from image...`);

    const imageBase64 = await encodeBase64(image.path);
    const imageMimeType = getMimeType(image.originalname);

    const avatarPayload = {
      inline_data: {
        mime_type: imageMimeType,
        data: imageBase64,
      },
    };

    const avatarUrl = `${VISIONSTORY_API_BASE}/api/v1/avatar`;

    const avatarHeaders = new Headers();
    avatarHeaders.set("X-API-Key", VISIONSTORY_API_KEY);
    avatarHeaders.set("Content-Type", "application/json");
    avatarHeaders.set("Accept", "application/json");

    const avatarResponse = await fetch(avatarUrl, {
      method: "POST",
      headers: avatarHeaders,
      body: JSON.stringify(avatarPayload),
    });

    if (!avatarResponse.ok) {
      const errorText = await avatarResponse.text();
      throw new Error(`Avatar creation failed: ${avatarResponse.status} ${errorText}`);
    }

    const avatarData = await avatarResponse.json();
    const avatarId = avatarData?.data?.avatar_id;

    if (!avatarId) {
      throw new Error("Avatar creation succeeded but no avatar_id was returned.");
    }

    console.log(`[Job ${jobId}] Avatar created: ${avatarId}`);

    // Step 2: 비디오 생성
    await updateJobProgress(jobId, {
      progress: {
        currentStep: "video_generation",
        stepNumber: 2,
        totalSteps: 3,
        message: "아바타 영상 생성 중...",
      },
    });

    console.log(`[Job ${jobId}] Step 2: Creating video from avatar and audio...`);

    const audioBase64 = await encodeBase64(audio.path);
    const audioMimeType = getMimeType(audio.originalname);

    const videoPayload = {
      model_id: "vs_talk_v1",
      avatar_id: avatarId,
      audio_script: {
        inline_data: {
          mime_type: audioMimeType,
          data: audioBase64,
        },
        voice_change: true,
        denoise: true,
      },
      emotion: "news",
      aspect_ratio: "9:16",
      resolution: "720p",
    };

    const videoUrl = `${VISIONSTORY_API_BASE}/api/v1/video`;

    const videoResponse = await fetch(videoUrl, {
      method: "POST",
      headers: {
        "X-API-Key": VISIONSTORY_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(videoPayload),
    });

    if (!videoResponse.ok) {
      const errorText = await videoResponse.text();
      throw new Error(`Video creation failed: ${videoResponse.status} ${errorText}`);
    }

    const videoData = await videoResponse.json();
    const videoId = videoData?.data?.video_id;

    if (!videoId) {
      throw new Error("Video creation request succeeded but no video_id was returned.");
    }

    console.log(`[Job ${jobId}] Video creation started: ${videoId}`);

    // Step 3: 영상 생성 완료까지 폴링
    await updateJobProgress(jobId, {
      progress: {
        currentStep: "video_generation",
        stepNumber: 3,
        totalSteps: 3,
        message: "영상 생성 완료 대기 중... (2-10분 소요)",
      },
    });

    console.log(`[Job ${jobId}] Step 3: Polling for video completion...`);

    const timeout = 3600; // seconds (1 hour)
    const pollInterval = 10; // seconds
    let waitTime = 0;
    let finalVideoData = null;

    while (waitTime <= timeout) {
      await new Promise((resolve) => setTimeout(resolve, pollInterval * 1000));
      waitTime += pollInterval;

      const statusResponse = await fetch(
        `${VISIONSTORY_API_BASE}/api/v1/video?video_id=${videoId}`,
        {
          method: "GET",
          headers: {
            "X-API-Key": VISIONSTORY_API_KEY,
            "Content-Type": "application/json",
          },
        }
      );

      if (!statusResponse.ok) {
        const errorText = await statusResponse.text();
        console.error(`[Job ${jobId}] Status check failed: ${errorText}`);
        break;
      }

      const statusData = await statusResponse.json();
      const status = statusData?.data?.status;

      console.log(`[Job ${jobId}] Video status (${waitTime}s): ${status}`);

      // 진행 상황 업데이트
      await updateJobProgress(jobId, {
        progress: {
          currentStep: "video_generation",
          stepNumber: 3,
          totalSteps: 3,
          message: `영상 생성 중... (${waitTime}초 경과)`,
        },
      });

      if (status === "created") {
        finalVideoData = statusData.data;
        break;
      } else if (status === "failed") {
        throw new Error("Video generation failed.");
      }
    }

    if (!finalVideoData || !finalVideoData.video_url) {
      throw new Error("Video generation timed out or video_url not found.");
    }

    console.log(`[Job ${jobId}] Video completed: ${finalVideoData.video_url}`);

    // 완료 상태 업데이트
    await updateJobProgress(jobId, {
      status: "completed",
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      videoUrl: finalVideoData.video_url,
      progress: {
        currentStep: "completed",
        stepNumber: 3,
        totalSteps: 3,
        message: "아바타 영상 생성 완료!",
      },
    });

    console.log(`[Job ${jobId}] Job completed successfully`);
  } catch (error) {
    console.error(`[Job ${jobId}] Job failed:`, error);

    // 실패 상태 업데이트
    await updateJobProgress(jobId, {
      status: "failed",
      errorMessage: error.message,
      progress: {
        currentStep: "failed",
        stepNumber: 0,
        totalSteps: 3,
        message: `오류: ${error.message}`,
      },
    });
  }
}

// Firestore 작업 업데이트 헬퍼 함수
async function updateJobProgress(jobId, updates) {
  try {
    await db.collection("avatarJobs").doc(jobId).update({
      ...updates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error(`Failed to update job ${jobId}:`, error);
  }
}

// 작업 상태 조회
app.get("/jobs/:jobId", async (req, res) => {
  try {
    const { jobId } = req.params;

    const jobDoc = await db.collection("avatarJobs").doc(jobId).get();

    if (!jobDoc.exists) {
      return res.status(404).json({
        error: "Job not found",
      });
    }

    res.json({
      success: true,
      job: {
        jobId: jobDoc.id,
        ...jobDoc.data(),
      },
    });
  } catch (error) {
    console.error("Failed to get job status:", error);
    res.status(500).json({
      error: "Failed to get job status.",
      details: error.message,
    });
  }
});

// ============================================
// Cloud Tasks Worker 엔드포인트
// ============================================

// 워커: 아바타 비디오 생성 처리 (수시간 소요 가능)
app.post("/worker/process-avatar", async (req, res) => {
  const { jobId, imagePath, audioPath, imageFilename, audioFilename } = req.body;

  console.log(`[Worker] Processing job ${jobId}`);

  try {
    // 1. 상태 업데이트: processing
    await updateJobProgress(jobId, {
      status: "processing",
      progress: {
        currentStep: "avatar_creation",
        stepNumber: 1,
        totalSteps: 3,
        message: "아바타 생성 시작...",
      },
    });

    // 2. 아바타 생성
    console.log(`[Worker ${jobId}] Step 1: Creating avatar`);
    
    const imageBase64 = await encodeBase64(imagePath);
    const imageMimeType = getMimeType(imageFilename);

    const avatarPayload = {
      inline_data: {
        mime_type: imageMimeType,
        data: imageBase64,
      },
    };

    const avatarUrl = `${VISIONSTORY_API_BASE}/api/v1/avatar`;
    const avatarHeaders = new Headers();
    avatarHeaders.set("X-API-Key", VISIONSTORY_API_KEY);
    avatarHeaders.set("Content-Type", "application/json");
    avatarHeaders.set("Accept", "application/json");

    const avatarResponse = await fetch(avatarUrl, {
      method: "POST",
      headers: avatarHeaders,
      body: JSON.stringify(avatarPayload),
    });

    if (!avatarResponse.ok) {
      const errorText = await avatarResponse.text();
      throw new Error(`Avatar creation failed: ${avatarResponse.status} ${errorText}`);
    }

    const avatarData = await avatarResponse.json();
    const avatarId = avatarData?.data?.avatar_id;

    if (!avatarId) {
      throw new Error("Avatar creation succeeded but no avatar_id was returned.");
    }

    console.log(`[Worker ${jobId}] Avatar created: ${avatarId}`);

    // 3. 비디오 생성 요청
    await updateJobProgress(jobId, {
      progress: {
        currentStep: "video_generation",
        stepNumber: 2,
        totalSteps: 3,
        message: "비디오 생성 요청 중...",
      },
    });

    console.log(`[Worker ${jobId}] Step 2: Requesting video generation`);

    const audioBase64 = await encodeBase64(audioPath);
    const audioMimeType = getMimeType(audioFilename);

    const videoPayload = {
      model_id: "vs_talk_v1",
      avatar_id: avatarId,
      audio_script: {
        inline_data: {
          mime_type: audioMimeType,
          data: audioBase64,
        },
        voice_change: true,
        denoise: true,
      },
      emotion: "news",
      aspect_ratio: "9:16",
      resolution: "720p",
    };

    const videoUrl = `${VISIONSTORY_API_BASE}/api/v1/video`;

    const videoResponse = await fetch(videoUrl, {
      method: "POST",
      headers: {
        "X-API-Key": VISIONSTORY_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(videoPayload),
    });

    if (!videoResponse.ok) {
      const errorText = await videoResponse.text();
      throw new Error(`Video creation failed: ${videoResponse.status} ${errorText}`);
    }

    const videoData = await videoResponse.json();
    const videoId = videoData?.data?.video_id;

    if (!videoId) {
      throw new Error("Video creation request succeeded but no video_id was returned.");
    }

    console.log(`[Worker ${jobId}] Video generation started: ${videoId}`);

    // 4. 폴링 시작 (수시간 소요 가능)
    await updateJobProgress(jobId, {
      progress: {
        currentStep: "video_generation",
        stepNumber: 3,
        totalSteps: 3,
        message: "비디오 생성 중... (폴링 시작)",
      },
    });

    console.log(`[Worker ${jobId}] Step 3: Polling for video completion`);

    const maxAttempts = 360; // 최대 60시간 (10분 × 360)
    const pollInterval = 10 * 60 * 1000; // 10분
    let attempts = 0;
    let finalVideoData = null;

    while (attempts < maxAttempts) {
      await new Promise((resolve) => setTimeout(resolve, pollInterval));
      attempts++;

      const elapsedMinutes = attempts * 10;
      console.log(`[Worker ${jobId}] Polling attempt ${attempts} (${elapsedMinutes}분 경과)`);

      const statusResponse = await fetch(
        `${VISIONSTORY_API_BASE}/api/v1/video?video_id=${videoId}`,
        {
          method: "GET",
          headers: {
            "X-API-Key": VISIONSTORY_API_KEY,
            "Content-Type": "application/json",
          },
        }
      );

      if (!statusResponse.ok) {
        const errorText = await statusResponse.text();
        console.error(`[Worker ${jobId}] Status check failed: ${errorText}`);
        // 일시적 오류일 수 있으므로 계속 진행
        continue;
      }

      const statusData = await statusResponse.json();
      const status = statusData?.data?.status;

      console.log(`[Worker ${jobId}] Video status: ${status} (${elapsedMinutes}분 경과)`);

      // 진행 상황 업데이트
      await updateJobProgress(jobId, {
        progress: {
          currentStep: "video_generation",
          stepNumber: 3,
          totalSteps: 3,
          message: `비디오 생성 중... (${elapsedMinutes}분 경과, 상태: ${status})`,
        },
      });

      if (status === "created") {
        finalVideoData = statusData.data;
        break;
      } else if (status === "failed") {
        throw new Error("Video generation failed at VisionStory.");
      }
    }

    if (!finalVideoData || !finalVideoData.video_url) {
      throw new Error(
        `Video generation timed out after ${attempts * 10} minutes (${attempts} attempts)`
      );
    }

    console.log(`[Worker ${jobId}] Video completed: ${finalVideoData.video_url}`);

    // 5. 완료 상태 업데이트
    await updateJobProgress(jobId, {
      status: "completed",
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      videoUrl: finalVideoData.video_url,
      progress: {
        currentStep: "completed",
        stepNumber: 3,
        totalSteps: 3,
        message: "아바타 영상 생성 완료!",
      },
    });

    console.log(`[Worker ${jobId}] Job completed successfully`);

    // Cloud Tasks에 성공 응답
    res.json({
      success: true,
      jobId: jobId,
      videoUrl: finalVideoData.video_url,
    });
  } catch (error) {
    console.error(`[Worker ${jobId}] Job failed:`, error);

    // 실패 상태 업데이트
    await updateJobProgress(jobId, {
      status: "failed",
      errorMessage: error.message,
      progress: {
        currentStep: "failed",
        stepNumber: 0,
        totalSteps: 3,
        message: `오류: ${error.message}`,
      },
    });

    // Cloud Tasks에 실패 응답 (자동 재시도됨)
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

app.post(
  "/generate",
  upload.fields([
    { name: "image", maxCount: 1 },
    { name: "audio", maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const image = req.files?.image?.[0];
      const audio = req.files?.audio?.[0];

      if (!image || !audio) {
        return res.status(400).json({
          error: "image and audio files are both required.",
        });
      }

      if (!VISIONSTORY_API_KEY) {
        return res.status(500).json({
          error:
            "VisionStory API key is not configured. Please set VISIONSTORY_API_KEY environment variable.",
        });
      }

      console.log("[VisionStory] Step 1: Creating avatar from image...");
      console.log(`[VisionStory] API Key: ${VISIONSTORY_API_KEY ? VISIONSTORY_API_KEY.substring(0, 10) + "..." : "NOT SET"}`);
      console.log(`[VisionStory] Base URL: ${VISIONSTORY_API_BASE}`);

      // Step 1: 이미지로 아바타 생성
      const imageBase64 = await encodeBase64(image.path);
      const imageMimeType = getMimeType(image.originalname);

      const avatarPayload = {
        inline_data: {
          mime_type: imageMimeType,
          data: imageBase64,
        },
      };

      const avatarUrl = `${VISIONSTORY_API_BASE}/api/v1/avatar`;
      console.log(`[VisionStory] Request URL: ${avatarUrl}`);

      const avatarHeaders = new Headers();
      avatarHeaders.set("X-API-Key", VISIONSTORY_API_KEY);
      avatarHeaders.set("Content-Type", "application/json");
      avatarHeaders.set("Accept", "application/json");

      console.log(`[VisionStory] Headers:`, {
        "X-API-Key": VISIONSTORY_API_KEY ? VISIONSTORY_API_KEY.substring(0, 10) + "..." : "NOT SET",
        "Content-Type": "application/json",
        "Accept": "application/json",
      });

      const avatarResponse = await fetch(avatarUrl, {
        method: "POST",
        headers: avatarHeaders,
        body: JSON.stringify(avatarPayload),
      });

      console.log(`[VisionStory] Response status: ${avatarResponse.status}`);

      if (!avatarResponse.ok) {
        const errorText = await avatarResponse.text();
        console.error("[VisionStory] Avatar creation failed:");
        console.error(`[VisionStory] Status: ${avatarResponse.status}`);
        console.error(`[VisionStory] API Key used: ${VISIONSTORY_API_KEY ? VISIONSTORY_API_KEY.substring(0, 10) + "..." : "NOT SET"}`);
        console.error(`[VisionStory] Error response:`, errorText);
        
        try {
          const errorJson = JSON.parse(errorText);
          console.error(`[VisionStory] Parsed error:`, JSON.stringify(errorJson, null, 2));
          
          // 에러 메시지에서 jwt_token 관련 에러인지 확인
          if (errorJson?.error?.message?.includes("jwt_token") || errorText.includes("jwt_token")) {
            console.error(`[VisionStory] JWT Token error detected - this might indicate an API key issue`);
          }
        } catch (e) {
          console.error(`[VisionStory] Error is not JSON`);
        }
        
        return res.status(avatarResponse.status).json({
          error: "Failed to create avatar from image.",
          status: avatarResponse.status,
          details: errorText,
        });
      }

      const avatarData = await avatarResponse.json();
      const avatarId = avatarData?.data?.avatar_id;

      if (!avatarId) {
        return res.status(500).json({
          error: "Avatar creation succeeded but no avatar_id was returned.",
          response: avatarData,
        });
      }

      console.log(`[VisionStory] Avatar created: ${avatarId}`);
      console.log("[VisionStory] Step 2: Creating video from avatar and audio...");

      // Step 2: 아바타와 오디오로 영상 생성
      const audioBase64 = await encodeBase64(audio.path);
      const audioMimeType = getMimeType(audio.originalname);

      const videoPayload = {
        model_id: "vs_talk_v1",
        avatar_id: avatarId,
        audio_script: {
          inline_data: {
            mime_type: audioMimeType,
            data: audioBase64,
          },
          voice_change: true,
          denoise: true,
        },
        emotion: "news",
        aspect_ratio: "9:16",
        resolution: "720p",
      };

      const videoUrl = `${VISIONSTORY_API_BASE}/api/v1/video`;
      console.log(`[VisionStory] Request URL: ${videoUrl}`);

      const videoResponse = await fetch(videoUrl, {
        method: "POST",
        headers: {
          "X-API-Key": VISIONSTORY_API_KEY,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(videoPayload),
      });

      if (!videoResponse.ok) {
        const errorText = await videoResponse.text();
        console.error("[VisionStory] Video creation failed:", errorText);
        return res.status(videoResponse.status).json({
          error: "Failed to create video.",
          status: videoResponse.status,
          details: errorText,
        });
      }

      const videoData = await videoResponse.json();
      const videoId = videoData?.data?.video_id;

      if (!videoId) {
        return res.status(500).json({
          error: "Video creation request succeeded but no video_id was returned.",
          response: videoData,
        });
      }

      console.log(`[VisionStory] Video creation started: ${videoId}`);
      console.log("[VisionStory] Step 3: Polling for video completion...");

      // Step 3: 영상 생성 완료까지 폴링
      const timeout = 3600; // seconds (1 hour)
      const pollInterval = 10; // seconds
      let waitTime = 0;
      let finalVideoData = null;

      while (waitTime <= timeout) {
        await new Promise((resolve) => setTimeout(resolve, pollInterval * 1000));
        waitTime += pollInterval;

        const statusResponse = await fetch(
          `${VISIONSTORY_API_BASE}/api/v1/video?video_id=${videoId}`,
          {
            method: "GET",
            headers: {
              "X-API-Key": VISIONSTORY_API_KEY,
              "Content-Type": "application/json",
            },
          }
        );

        if (!statusResponse.ok) {
          const errorText = await statusResponse.text();
          console.error(`[VisionStory] Status check failed: ${errorText}`);
          break;
        }

        const statusData = await statusResponse.json();
        const status = statusData?.data?.status;

        console.log(`[VisionStory] Video status (${waitTime}s): ${status}`);

        if (status === "created") {
          finalVideoData = statusData.data;
          break;
        } else if (status === "failed") {
          return res.status(500).json({
            error: "Video generation failed.",
            statusData,
          });
        }
      }

      if (!finalVideoData || !finalVideoData.video_url) {
        return res.status(504).json({
          error: "Video generation timed out or video_url not found.",
          videoId,
          message: "Please check the video status manually using /status/:videoId",
          checkStatusUrl: `${req.protocol}://${req.get("host")}/status/${videoId}`,
        });
      }

      console.log(`[VisionStory] Video completed: ${finalVideoData.video_url}`);

      res.json({
        status: "completed",
        source: "visionstory-ai",
        videoUrl: finalVideoData.video_url,
        videoId,
        detail: finalVideoData,
      });
    } catch (error) {
      console.error("Failed to submit generation request:", error);
      res.status(500).json({
        error: "Failed to submit generation request.",
        details: error.message,
      });
    }
  }
);

// 영상 상태 확인 엔드포인트
app.get("/status/:videoId", async (req, res) => {
  try {
    const { videoId } = req.params;

    if (!VISIONSTORY_API_KEY) {
      return res.status(500).json({
        error: "VisionStory API key is not configured.",
      });
    }

    const apiResponse = await fetch(
      `${VISIONSTORY_API_BASE}/api/v1/video?video_id=${videoId}`,
      {
        method: "GET",
        headers: {
          "X-API-Key": VISIONSTORY_API_KEY,
          "Content-Type": "application/json",
        },
      }
    );

    if (!apiResponse.ok) {
      const errorText = await apiResponse.text();
      return res.status(apiResponse.status).json({
        error: "Failed to check video status.",
        details: errorText,
      });
    }

    const apiData = await apiResponse.json();
    const videoUrl = apiData?.data?.video_url;
    const status = apiData?.data?.status;

    if (status === "created" && videoUrl) {
      return res.json({
        status: "completed",
        source: "visionstory-ai",
        videoUrl,
        videoId,
        detail: apiData.data,
      });
    }

    res.json({
      status: status || "processing",
      videoId,
      message: `Video generation is ${status || "still in progress"}.`,
      detail: apiData.data,
    });
  } catch (error) {
    console.error("Failed to check video status:", error);
    res.status(500).json({
      error: "Failed to check video status.",
      details: error.message,
    });
  }
});

app.listen(port, () => {
  console.log(`VisionStory AI Talking Head backend listening on http://localhost:${port}`);
  console.log(
    `API Key configured: ${VISIONSTORY_API_KEY ? "Yes" : "No (set VISIONSTORY_API_KEY)"}`
  );
  console.log(`API Base URL: ${VISIONSTORY_API_BASE}`);
});

