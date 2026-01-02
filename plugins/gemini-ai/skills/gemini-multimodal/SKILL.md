---
name: gemini-multimodal
description: This skill provides guidance for Gemini multimodal capabilities including image understanding, image generation (Nano Banana), video generation (Veo), and audio processing. Use when the user asks about "image analysis", "generate image", "Nano Banana", "Veo", "video generation", "multimodal", "vision API", or needs help with non-text content.
---

# Gemini Multimodal Capabilities

Complete guide to Gemini's multimodal features: image understanding, image generation (Nano Banana), video generation (Veo), and audio processing.

## Capability Matrix

| Capability | Models | API |
|------------|--------|-----|
| **Image Understanding** | All models | Direct |
| **Image Generation** | 2.5 Flash Image, 3 Pro Image | Direct |
| **Video Understanding** | 1.5 Pro, 2.0 Flash | Direct |
| **Video Generation** | Veo 2.0, Veo 3.1 | Direct |
| **Audio Understanding** | 1.5 Pro, 2.0 Flash | Direct |
| **Audio Generation** | 2.0 Flash Live | Direct |

## Image Understanding

### Analyze Single Image

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';
import * as fs from 'fs';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

// From file
async function analyzeImage(imagePath: string, prompt: string) {
  const imageData = fs.readFileSync(imagePath);
  const base64 = imageData.toString('base64');
  const mimeType = imagePath.endsWith('.png') ? 'image/png' : 'image/jpeg';

  const result = await model.generateContent([
    { text: prompt },
    {
      inlineData: {
        mimeType,
        data: base64,
      },
    },
  ]);

  return result.response.text();
}

// Usage
const description = await analyzeImage(
  './product.jpg',
  'Describe this product for an e-commerce listing. Include color, features, and condition.'
);
```

### From URL

```typescript
async function analyzeImageUrl(url: string, prompt: string) {
  const response = await fetch(url);
  const buffer = await response.arrayBuffer();
  const base64 = Buffer.from(buffer).toString('base64');

  const result = await model.generateContent([
    { text: prompt },
    {
      inlineData: {
        mimeType: 'image/jpeg',
        data: base64,
      },
    },
  ]);

  return result.response.text();
}
```

### Multiple Images

```typescript
async function compareImages(images: string[], prompt: string) {
  const parts: any[] = [{ text: prompt }];

  for (const imagePath of images) {
    const imageData = fs.readFileSync(imagePath);
    parts.push({
      inlineData: {
        mimeType: 'image/jpeg',
        data: imageData.toString('base64'),
      },
    });
  }

  const result = await model.generateContent(parts);
  return result.response.text();
}

// Usage
const comparison = await compareImages(
  ['./product-old.jpg', './product-new.jpg'],
  'Compare these two product versions. What changed?'
);
```

## Image Generation (Nano Banana)

### Nano Banana (Fast)

```typescript
const imageModel = genAI.getGenerativeModel({
  model: 'gemini-2.5-flash-image',
});

async function generateImage(prompt: string): Promise<Buffer> {
  const result = await imageModel.generateContent({
    contents: [{
      role: 'user',
      parts: [{ text: prompt }],
    }],
    generationConfig: {
      responseModalities: ['image'],
    },
  });

  const imagePart = result.response.candidates?.[0]?.content?.parts?.find(
    p => p.inlineData
  );

  if (!imagePart?.inlineData) {
    throw new Error('No image generated');
  }

  return Buffer.from(imagePart.inlineData.data, 'base64');
}

// Save to file
const imageBuffer = await generateImage(
  'A modern smartphone on a minimalist desk, professional product photography'
);
fs.writeFileSync('generated.png', imageBuffer);
```

### Nano Banana Pro (High Quality)

Best for:
- Text in images (legible text rendering)
- Professional assets
- Complex scenes
- Brand consistency

```typescript
const proModel = genAI.getGenerativeModel({
  model: 'gemini-3-pro-image-preview',
});

async function generateProImage(prompt: string): Promise<Buffer> {
  const result = await proModel.generateContent({
    contents: [{
      role: 'user',
      parts: [{
        text: `Create a high-quality professional image:

${prompt}

Requirements:
- 4K resolution quality
- Sharp details
- Professional lighting
- Any text must be perfectly legible
`,
      }],
    }],
    generationConfig: {
      responseModalities: ['image'],
    },
  });

  const imagePart = result.response.candidates?.[0]?.content?.parts?.find(
    p => p.inlineData
  );

  return Buffer.from(imagePart.inlineData.data, 'base64');
}
```

### Image Editing

```typescript
async function editImage(
  imagePath: string,
  editPrompt: string
): Promise<Buffer> {
  const imageData = fs.readFileSync(imagePath);
  const model = genAI.getGenerativeModel({
    model: 'gemini-3-pro-image-preview',
  });

  const result = await model.generateContent({
    contents: [{
      role: 'user',
      parts: [
        {
          inlineData: {
            mimeType: 'image/jpeg',
            data: imageData.toString('base64'),
          },
        },
        {
          text: `Edit this image: ${editPrompt}`,
        },
      ],
    }],
    generationConfig: {
      responseModalities: ['image'],
    },
  });

  const imagePart = result.response.candidates?.[0]?.content?.parts?.find(
    p => p.inlineData
  );

  return Buffer.from(imagePart.inlineData.data, 'base64');
}

// Usage
const edited = await editImage(
  './product.jpg',
  'Remove the background and replace with solid white'
);
```

### Image-to-Image

```typescript
async function styleTransfer(
  sourceImage: string,
  styleImage: string,
  instructions: string
): Promise<Buffer> {
  const sourceData = fs.readFileSync(sourceImage);
  const styleData = fs.readFileSync(styleImage);

  const model = genAI.getGenerativeModel({
    model: 'gemini-3-pro-image-preview',
  });

  const result = await model.generateContent({
    contents: [{
      role: 'user',
      parts: [
        {
          inlineData: {
            mimeType: 'image/jpeg',
            data: sourceData.toString('base64'),
          },
        },
        {
          inlineData: {
            mimeType: 'image/jpeg',
            data: styleData.toString('base64'),
          },
        },
        {
          text: `Apply the style from the second image to the first. ${instructions}`,
        },
      ],
    }],
    generationConfig: {
      responseModalities: ['image'],
    },
  });

  const imagePart = result.response.candidates?.[0]?.content?.parts?.find(
    p => p.inlineData
  );

  return Buffer.from(imagePart.inlineData.data, 'base64');
}
```

## Video Understanding

### Analyze Video

```typescript
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro' });

async function analyzeVideo(videoPath: string, prompt: string) {
  const videoData = fs.readFileSync(videoPath);
  const mimeType = videoPath.endsWith('.mp4') ? 'video/mp4' : 'video/webm';

  const result = await model.generateContent([
    { text: prompt },
    {
      inlineData: {
        mimeType,
        data: videoData.toString('base64'),
      },
    },
  ]);

  return result.response.text();
}

// Usage
const analysis = await analyzeVideo(
  './product-demo.mp4',
  'Summarize this product demo video. What are the key features shown?'
);
```

### Video Timestamps

```typescript
const summary = await analyzeVideo(
  './tutorial.mp4',
  'Create a timestamped summary of this video. Format: [MM:SS] Description'
);

// Output:
// [00:00] Introduction to the app
// [00:45] Creating your first project
// [02:30] Adding products
// ...
```

## Video Generation (Veo)

### Text-to-Video

```typescript
const veoModel = genAI.getGenerativeModel({
  model: 'veo-2.0',
});

async function generateVideo(prompt: string): Promise<Buffer> {
  const result = await veoModel.generateContent({
    contents: [{
      role: 'user',
      parts: [{
        text: `Create a short video:

${prompt}

Requirements:
- 5-10 seconds duration
- 1080p quality
- Smooth motion
`,
      }],
    }],
    generationConfig: {
      responseModalities: ['video'],
    },
  });

  const videoPart = result.response.candidates?.[0]?.content?.parts?.find(
    p => p.inlineData?.mimeType?.includes('video')
  );

  return Buffer.from(videoPart.inlineData.data, 'base64');
}

// Usage
const video = await generateVideo(
  'A smartphone rotating 360 degrees on a white background, studio lighting'
);
fs.writeFileSync('product-spin.mp4', video);
```

### Image-to-Video

```typescript
async function imageToVideo(
  imagePath: string,
  motion: string
): Promise<Buffer> {
  const imageData = fs.readFileSync(imagePath);

  const result = await veoModel.generateContent({
    contents: [{
      role: 'user',
      parts: [
        {
          inlineData: {
            mimeType: 'image/jpeg',
            data: imageData.toString('base64'),
          },
        },
        {
          text: `Animate this image: ${motion}`,
        },
      ],
    }],
    generationConfig: {
      responseModalities: ['video'],
      videoDuration: 5,
    },
  });

  const videoPart = result.response.candidates?.[0]?.content?.parts?.find(
    p => p.inlineData?.mimeType?.includes('video')
  );

  return Buffer.from(videoPart.inlineData.data, 'base64');
}

// Usage
const animated = await imageToVideo(
  './product.jpg',
  'Subtle camera zoom in, floating particles, premium feel'
);
```

## Audio Processing

### Transcribe Audio

```typescript
async function transcribeAudio(audioPath: string): Promise<string> {
  const audioData = fs.readFileSync(audioPath);
  const mimeType = audioPath.endsWith('.mp3') ? 'audio/mp3' : 'audio/wav';

  const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro' });

  const result = await model.generateContent([
    { text: 'Transcribe this audio accurately. Include speaker labels if multiple speakers.' },
    {
      inlineData: {
        mimeType,
        data: audioData.toString('base64'),
      },
    },
  ]);

  return result.response.text();
}
```

### Analyze Audio

```typescript
async function analyzeAudio(audioPath: string, prompt: string) {
  const audioData = fs.readFileSync(audioPath);

  const result = await model.generateContent([
    { text: prompt },
    {
      inlineData: {
        mimeType: 'audio/mp3',
        data: audioData.toString('base64'),
      },
    },
  ]);

  return result.response.text();
}

// Usage
const sentiment = await analyzeAudio(
  './customer-call.mp3',
  'Analyze the customer sentiment in this call. Was the issue resolved?'
);
```

## Multimodal Chat

```typescript
const chat = model.startChat();

// Send text
await chat.sendMessage('I\'m looking for a new phone');

// Send image
const productImage = fs.readFileSync('./phones.jpg');
const response = await chat.sendMessage([
  { text: 'Which of these would you recommend for photography?' },
  {
    inlineData: {
      mimeType: 'image/jpeg',
      data: productImage.toString('base64'),
    },
  },
]);

console.log(response.response.text());
```

## Practical Examples

### E-commerce Product Listing

```typescript
async function generateProductListing(imagePath: string) {
  const imageData = fs.readFileSync(imagePath);

  const result = await model.generateContent([
    {
      text: `Analyze this product image and generate an e-commerce listing in JSON:

{
  "title": "Product title (50-80 chars)",
  "description": "Compelling description (150-200 words)",
  "features": ["feature1", "feature2", ...],
  "category": "suggested category",
  "keywords": ["keyword1", ...]
}`,
    },
    {
      inlineData: {
        mimeType: 'image/jpeg',
        data: imageData.toString('base64'),
      },
    },
  ]);

  return JSON.parse(result.response.text());
}
```

### Receipt/Invoice OCR

```typescript
async function extractReceiptData(imagePath: string) {
  const imageData = fs.readFileSync(imagePath);

  const result = await model.generateContent([
    {
      text: `Extract all data from this receipt/invoice as JSON:

{
  "vendor": "business name",
  "date": "YYYY-MM-DD",
  "items": [
    {"name": "item", "quantity": 1, "price": 0.00}
  ],
  "subtotal": 0.00,
  "tax": 0.00,
  "total": 0.00,
  "paymentMethod": "cash/card/mpesa"
}`,
    },
    {
      inlineData: {
        mimeType: 'image/jpeg',
        data: imageData.toString('base64'),
      },
    },
  ]);

  return JSON.parse(result.response.text());
}
```

### Content Moderation

```typescript
async function moderateImage(imagePath: string): Promise<{
  safe: boolean;
  categories: Record<string, boolean>;
}> {
  const imageData = fs.readFileSync(imagePath);

  const result = await model.generateContent([
    {
      text: `Analyze this image for content safety. Return JSON:

{
  "safe": true/false,
  "categories": {
    "adult": true/false,
    "violence": true/false,
    "hate": true/false,
    "selfHarm": true/false
  },
  "reason": "explanation if unsafe"
}`,
    },
    {
      inlineData: {
        mimeType: 'image/jpeg',
        data: imageData.toString('base64'),
      },
    },
  ]);

  return JSON.parse(result.response.text());
}
```

## File Size Limits

| Content Type | Max Size |
|--------------|----------|
| Image | 20MB |
| Audio | 9.5 hours |
| Video | 1 hour or 2GB |
| PDF | 1000 pages |

## Best Practices

1. **Compress images** - Resize before sending to reduce costs
2. **Use appropriate model** - Flash for speed, Pro for quality
3. **Specific prompts** - Guide the model to extract what you need
4. **Handle failures** - Some content may be filtered
5. **Cache results** - Don't reprocess unchanged content

## Resources

- [Vision API Docs](https://ai.google.dev/gemini-api/docs/vision)
- [Image Generation](https://ai.google.dev/gemini-api/docs/image-generation)
- [Audio Processing](https://ai.google.dev/gemini-api/docs/audio)
