const functions = require("firebase-functions");
const fetch = require("node-fetch");
require("dotenv").config();

exports.generateQuestion = functions.https.onRequest(async (req, res) => {
  try {
    const apiKey = process.env.GEMINI_API_KEY;

    const { role, level, techStack } = req.body;

    const prompt = `
Generate ONE interview question for:
Role: ${role}
Level: ${level}
Tech: ${techStack.join(", ")}
Keep it short and realistic.
`;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [{ text: prompt }],
            },
          ],
        }),
      }
    );

    const data = await response.json();

    const question =
      data.candidates?.[0]?.content?.parts?.[0]?.text ||
      "No question generated";

    res.json({ question });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Something went wrong" });
  }
});