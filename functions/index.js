const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const fetch = require("node-fetch");
require("dotenv").config();

const GEMINI_MODEL = "gemini-1.5-flash";
const geminiApiKey = defineSecret("GEMINI_API_KEY");

function getApiKey() {
  const apiKey = geminiApiKey.value() || process.env.GEMINI_API_KEY;
  if (!apiKey || !apiKey.trim()) {
    throw new HttpsError(
      "failed-precondition",
      "GEMINI_API_KEY is missing in functions environment."
    );
  }
  return apiKey.trim();
}

async function callGemini({ prompt, responseMimeType = undefined }) {
  const apiKey = getApiKey();

  const body = {
    contents: [
      {
        parts: [{ text: prompt }],
      },
    ],
  };

  if (responseMimeType) {
    body.generationConfig = {
      temperature: 0.3,
      responseMimeType,
    };
  }

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    }
  );

  const payload = await response.json();
  if (!response.ok) {
    const message = payload?.error?.message || "Gemini request failed.";
    throw new HttpsError("internal", message);
  }

  const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text || !text.trim()) {
    throw new HttpsError(
      "internal",
      "Gemini returned an empty response."
    );
  }

  return text.trim();
}

function parseJsonArray(rawText) {
  const cleaned = rawText.replace(/```json|```/g, "").trim();

  try {
    const parsed = JSON.parse(cleaned);
    if (Array.isArray(parsed)) {
      return parsed.map((item) => String(item).trim()).filter(Boolean);
    }
  } catch (_) {
    // Continue to fragment parsing.
  }

  const match = cleaned.match(/\[[\s\S]*\]/);
  if (match) {
    try {
      const parsed = JSON.parse(match[0]);
      if (Array.isArray(parsed)) {
        return parsed.map((item) => String(item).trim()).filter(Boolean);
      }
    } catch (_) {
      // Continue to line parsing.
    }
  }

  const lineList = cleaned
    .split("\n")
    .map((line) => line.replace(/^[-*\d\.)\s]+/, "").replace(/"/g, "").trim())
    .filter(Boolean);

  return lineList;
}

function parseJsonObject(rawText) {
  const cleaned = rawText.replace(/```json|```/g, "").trim();
  const match = cleaned.match(/\{[\s\S]*\}/);
  const payload = match ? match[0] : cleaned;

  try {
    return JSON.parse(payload);
  } catch (_) {
    throw new HttpsError(
      "internal",
      "Failed to parse Gemini JSON object response."
    );
  }
}

exports.generateQuestion = onCall({secrets: [geminiApiKey]}, async (request) => {
  const data = request.data;
  const role = String(data?.role || "Software Engineer");
  const level = String(data?.level || "Junior");
  const techStack = Array.isArray(data?.techStack) ? data.techStack : [];
  const stack = techStack.length ? techStack.join(", ") : "general software";

  const prompt =
    `Generate ONE concise and realistic interview question for role="${role}", ` +
    `level="${level}", tech stack="${stack}". Return question text only.`;

  const text = await callGemini({ prompt });
  return { question: text };
});

exports.generatePopularRoles = onCall(
  {secrets: [geminiApiKey]},
  async (request) => {
    const data = request.data;
  const currentRole = String(data?.currentRole || "Software Engineer");
  const level = String(data?.level || "Junior");
  const techStack = Array.isArray(data?.techStack) ? data.techStack : [];
  const stack = techStack.length ? techStack.join(", ") : "general software";

  const prompt =
    `Given candidate profile role="${currentRole}", level="${level}", stack="${stack}", ` +
    "generate exactly 5 relevant interview target roles. Return only JSON array of strings.";

  const text = await callGemini({
    prompt,
    responseMimeType: "application/json",
  });
  const roles = parseJsonArray(text).slice(0, 5);

  if (!roles.length) {
    throw new HttpsError(
      "internal",
      "Could not parse popular roles from Gemini response."
    );
  }

  return { roles };
  }
);

exports.generatePracticeQuestions = onCall(
  {secrets: [geminiApiKey]},
  async (request) => {
    const data = request.data;
  const role = String(data?.role || "Software Engineer");
  const level = String(data?.level || "Junior");
  const techStack = Array.isArray(data?.techStack) ? data.techStack : [];
  const count = Number(data?.count) || 5;
  const stack = techStack.length ? techStack.join(", ") : "general software";

  const prompt =
    `Generate exactly ${count} interview practice questions for role="${role}", ` +
    `level="${level}", stack="${stack}". ` +
    "Return only a JSON array of strings with no markdown and no explanation.";

  const text = await callGemini({
    prompt,
    responseMimeType: "application/json",
  });
  const questions = parseJsonArray(text).slice(0, count);

  if (!questions.length) {
    throw new HttpsError(
      "internal",
      "Could not parse practice questions from Gemini response."
    );
  }

  return { questions };
  }
);

exports.evaluateAnswer = onCall({secrets: [geminiApiKey]}, async (request) => {
  const data = request.data;
  const role = String(data?.role || "Software Engineer");
  const level = String(data?.level || "Junior");
  const techStack = Array.isArray(data?.techStack) ? data.techStack : [];
  const question = String(data?.question || "");
  const answer = String(data?.answer || "");
  const stack = techStack.length ? techStack.join(", ") : "general software";

  if (!question.trim() || !answer.trim()) {
    throw new HttpsError(
      "invalid-argument",
      "Question and answer are required."
    );
  }

  const prompt =
    "You are an interview evaluator. Evaluate this candidate answer and return strict JSON only.\n" +
    `Role: ${role}\n` +
    `Level: ${level}\n` +
    `Tech Stack: ${stack}\n` +
    `Question: ${question}\n` +
    `Candidate Answer: ${answer}\n\n` +
    "JSON keys: score, feedback, modelAnswer. " +
    "score must be number from 0 to 10. feedback must be detailed and actionable.";

  const text = await callGemini({
    prompt,
    responseMimeType: "application/json",
  });
  const parsed = parseJsonObject(text);

  const rawScore = parsed.score;
  const score = typeof rawScore === "number" ? rawScore : Number(rawScore || 0);
  const feedback = String(parsed.feedback || "").trim();
  const modelAnswer = String(parsed.modelAnswer || "").trim();

  if (!feedback || !modelAnswer) {
    throw new HttpsError(
      "internal",
      "Gemini evaluation response is missing required fields."
    );
  }

  return {
    score: Math.max(0, Math.min(10, score)),
    feedback,
    modelAnswer,
  };
});