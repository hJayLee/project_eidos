import "dotenv/config";
import express from "express";
import cors from "cors";
import multer from "multer";
import fetch, { Headers } from "node-fetch";
import path from "path";
import { fileURLToPath } from "url";
import { promises as fs } from "fs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = process.env.PORT || 5001;

const publicDir = path.join(__dirname, "..", "public");
const uploadDir = path.join(publicDir, "uploads");
const resultDir = path.join(publicDir, "results");

// VisionStory API 설정
const VISIONSTORY_API_KEY = process.env.VISIONSTORY_API_KEY || "";
const VISIONSTORY_API_BASE = process.env.VISIONSTORY_API_BASE || "https://openapi.visionstory.ai";

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

