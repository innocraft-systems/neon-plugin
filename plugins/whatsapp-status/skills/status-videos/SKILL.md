---
name: status-videos
description: This skill provides guidance for generating WhatsApp Status videos using AI tools. Use when the user asks about "status video", "video template", "product video", "slideshow", "animated status", "Veo", "video generation", or needs help creating short videos for WhatsApp Status.
---

# WhatsApp Status Video Generation

Create short, engaging videos for WhatsApp Status using AI video generation and programmatic tools.

## Status Video Specs

| Property | Requirement |
|----------|-------------|
| Duration | 15-30 seconds optimal |
| Dimensions | 1080x1920 (9:16) |
| Format | MP4 |
| Max Size | 16MB |

## Video Generation Options

### 1. Veo (Google's Video Model)

Best for: Text-to-video, image-to-video, high quality

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY!);

async function generateVideo(prompt: string): Promise<Buffer> {
  const model = genAI.getGenerativeModel({
    model: 'veo-2.0', // or veo-3.1 when available
  });

  const result = await model.generateContent({
    contents: [{
      role: 'user',
      parts: [{
        text: `Create a 15-second WhatsApp Status video (1080x1920, 9:16):

${prompt}

Style: Professional, mobile-optimized, engaging
`,
      }],
    }],
    generationConfig: {
      responseModalities: ['video'],
      videoDuration: 15,
    },
  });

  const video = result.response.candidates?.[0]?.content?.parts?.find(
    p => p.inlineData?.mimeType?.includes('video')
  );

  return Buffer.from(video.inlineData.data, 'base64');
}
```

### 2. Remotion (Programmatic)

Best for: Template-based, consistent branding, data-driven

```bash
npm install @remotion/core @remotion/bundler @remotion/renderer
```

```typescript
// src/StatusVideo.tsx
import { AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig } from 'remotion';

interface ProductProps {
  productName: string;
  price: number;
  imageUrl: string;
  features: string[];
}

export const ProductShowcase: React.FC<ProductProps> = ({
  productName,
  price,
  imageUrl,
  features,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Animation timing
  const productEnter = Math.min(frame / (fps * 0.5), 1);
  const priceEnter = Math.min((frame - fps * 0.3) / (fps * 0.3), 1);

  return (
    <AbsoluteFill style={{ backgroundColor: '#1a1a2e' }}>
      {/* Product Image */}
      <Sequence from={0}>
        <div
          style={{
            position: 'absolute',
            top: '20%',
            left: '50%',
            transform: `translateX(-50%) scale(${productEnter})`,
          }}
        >
          <img src={imageUrl} style={{ width: 600, height: 600 }} />
        </div>
      </Sequence>

      {/* Product Name */}
      <Sequence from={15}>
        <h1
          style={{
            position: 'absolute',
            bottom: '35%',
            width: '100%',
            textAlign: 'center',
            color: 'white',
            fontSize: 72,
            fontWeight: 'bold',
          }}
        >
          {productName}
        </h1>
      </Sequence>

      {/* Price */}
      <Sequence from={25}>
        <div
          style={{
            position: 'absolute',
            bottom: '25%',
            width: '100%',
            textAlign: 'center',
            color: '#00ff88',
            fontSize: 96,
            fontWeight: 'bold',
            opacity: priceEnter,
          }}
        >
          KES {price.toLocaleString()}
        </div>
      </Sequence>

      {/* CTA */}
      <Sequence from={45}>
        <div
          style={{
            position: 'absolute',
            bottom: '10%',
            width: '100%',
            textAlign: 'center',
            color: 'white',
            fontSize: 48,
          }}
        >
          DM to Order
        </div>
      </Sequence>
    </AbsoluteFill>
  );
};
```

### 3. FFmpeg (Image Slideshow)

Best for: Quick slideshows from existing images

```typescript
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

interface SlideShowOptions {
  images: string[];
  output: string;
  duration: number; // seconds per image
  transition: 'fade' | 'slide' | 'none';
}

async function createSlideshow(options: SlideShowOptions): Promise<string> {
  const { images, output, duration, transition } = options;

  // Create file list
  const listFile = '/tmp/images.txt';
  const listContent = images
    .map(img => `file '${img}'\nduration ${duration}`)
    .join('\n');

  await fs.writeFile(listFile, listContent);

  // FFmpeg command for Status dimensions
  const cmd = `ffmpeg -y -f concat -safe 0 -i ${listFile} \
    -vf "scale=1080:1920:force_original_aspect_ratio=decrease,\
         pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,\
         ${transition === 'fade' ? 'fade=t=in:st=0:d=0.5,fade=t=out:st=' + (duration - 0.5) + ':d=0.5' : ''}" \
    -c:v libx264 -pix_fmt yuv420p \
    -r 30 ${output}`;

  await execAsync(cmd);
  return output;
}

// Usage
await createSlideshow({
  images: [
    './products/phone1.jpg',
    './products/phone2.jpg',
    './products/phone3.jpg',
  ],
  output: './status-videos/new-arrivals.mp4',
  duration: 3,
  transition: 'fade',
});
```

### 4. Creatomate API

Best for: Template-based videos, text animations

```typescript
import Creatomate from 'creatomate';

const client = new Creatomate.Client(process.env.CREATOMATE_API_KEY!);

async function createProductVideo(product: {
  name: string;
  price: number;
  imageUrl: string;
}) {
  const render = await client.render({
    templateId: 'your-template-id',
    modifications: {
      'Product Name': product.name,
      'Price': `KES ${product.price.toLocaleString()}`,
      'Product Image': product.imageUrl,
    },
    outputFormat: 'mp4',
  });

  return render.url;
}
```

## Video Template Types

### Product Reveal

```typescript
const productRevealPrompt = `
Create a 15-second product reveal video:

1. (0-3s) Dark screen, anticipation text "Coming Soon..."
2. (3-6s) Product silhouette appears, light rays
3. (6-10s) Full product reveal with spin
4. (10-12s) Price appears: KES 45,000
5. (12-15s) "Available Now - DM to Order"

Style: Premium, luxury feel, dramatic lighting
`;
```

### Flash Sale Countdown

```typescript
const flashSaleVideoPrompt = `
Create a 20-second flash sale video:

1. (0-3s) "FLASH SALE" text explosion
2. (3-8s) Countdown timer: 24:00:00 ticking
3. (8-15s) Products cycling with prices slashed
4. (15-20s) "Order Now Before It's Gone!"

Style: Urgent, red/orange colors, pulsing animations
`;
```

### Testimonial Video

```typescript
const testimonialVideoPrompt = `
Create a 15-second testimonial video:

Quote: "Best phone shop in Nairobi! Fast delivery."
Customer: Martin K.
Rating: 5 stars

1. (0-3s) 5 stars animate in
2. (3-10s) Quote text appears word by word
3. (10-15s) Customer name and "Verified Purchase" badge

Style: Trustworthy, clean, professional
`;
```

### Before/After

```typescript
const beforeAfterPrompt = `
Create a before/after comparison video:

Before: Old cracked phone screen
After: Brand new Samsung A54

1. (0-5s) "Before" label, sad old phone
2. (5-7s) Swipe transition
3. (7-12s) "After" label, shiny new phone
4. (12-15s) "Upgrade Today - KES 45,000"

Style: Dramatic transformation, satisfying reveal
`;
```

## Node.js Implementation

```typescript
import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';

const execAsync = promisify(exec);

interface VideoTemplate {
  type: 'slideshow' | 'text-overlay' | 'product-reveal';
  duration: number;
}

class StatusVideoGenerator {
  private outputDir: string;

  constructor(outputDir: string) {
    this.outputDir = outputDir;
  }

  // Create slideshow from images
  async slideshow(
    images: string[],
    options: {
      musicPath?: string;
      durationPerSlide?: number;
      includePrice?: string;
    } = {}
  ): Promise<string> {
    const { durationPerSlide = 3 } = options;
    const output = path.join(this.outputDir, `slideshow-${Date.now()}.mp4`);

    // Create input file list
    const listPath = '/tmp/ffmpeg-list.txt';
    const listContent = images
      .map(img => `file '${path.resolve(img)}'\nduration ${durationPerSlide}`)
      .join('\n') + `\nfile '${path.resolve(images[images.length - 1])}'`;

    await fs.writeFile(listPath, listContent);

    // Build FFmpeg command
    let cmd = `ffmpeg -y -f concat -safe 0 -i ${listPath}`;

    // Add music if provided
    if (options.musicPath) {
      cmd += ` -i "${options.musicPath}"`;
    }

    cmd += ` -vf "scale=1080:1920:force_original_aspect_ratio=decrease,`;
    cmd += `pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,`;
    cmd += `format=yuv420p"`;

    if (options.musicPath) {
      cmd += ` -c:a aac -shortest`;
    }

    cmd += ` -c:v libx264 -r 30 "${output}"`;

    await execAsync(cmd);
    return output;
  }

  // Add text overlay to video
  async addTextOverlay(
    videoPath: string,
    text: string,
    position: 'top' | 'center' | 'bottom' = 'bottom'
  ): Promise<string> {
    const output = path.join(this.outputDir, `overlay-${Date.now()}.mp4`);

    const y = position === 'top' ? '50' : position === 'center' ? '(h-text_h)/2' : 'h-text_h-100';

    const cmd = `ffmpeg -y -i "${videoPath}" \
      -vf "drawtext=text='${text}':fontsize=64:fontcolor=white:\
           x=(w-text_w)/2:y=${y}:shadowcolor=black:shadowx=2:shadowy=2" \
      -c:a copy "${output}"`;

    await execAsync(cmd);
    return output;
  }

  // Create countdown video
  async countdown(
    endTime: Date,
    backgroundImage: string
  ): Promise<string> {
    const output = path.join(this.outputDir, `countdown-${Date.now()}.mp4`);
    const duration = 15;

    // Create countdown frames
    const frames: string[] = [];
    for (let i = 0; i < duration * 30; i++) {
      const remaining = Math.max(0, endTime.getTime() - Date.now() - (i * 33));
      const hours = Math.floor(remaining / 3600000);
      const mins = Math.floor((remaining % 3600000) / 60000);
      const secs = Math.floor((remaining % 60000) / 1000);
      // Would generate frames with timer text
    }

    // This would be implemented with canvas or similar
    return output;
  }

  // Image to video with Ken Burns effect
  async kenBurns(
    imagePath: string,
    duration: number = 10
  ): Promise<string> {
    const output = path.join(this.outputDir, `kenburns-${Date.now()}.mp4`);

    const cmd = `ffmpeg -y -loop 1 -i "${imagePath}" \
      -vf "scale=1620:2880,zoompan=z='min(zoom+0.0015,1.5)':\
           d=${duration * 30}:s=1080x1920:fps=30" \
      -t ${duration} -c:v libx264 "${output}"`;

    await execAsync(cmd);
    return output;
  }
}

// Usage
const generator = new StatusVideoGenerator('./status-videos');

// Create product slideshow
const slideshow = await generator.slideshow([
  './products/phone1.jpg',
  './products/phone2.jpg',
  './products/phone3.jpg',
], {
  durationPerSlide: 3,
});
console.log('Slideshow created:', slideshow);

// Add price overlay
const withPrice = await generator.addTextOverlay(
  slideshow,
  'All Phones from KES 15,000',
  'bottom'
);
console.log('With overlay:', withPrice);
```

## Veo Integration (When Available)

```typescript
// Future Veo integration
async function generateWithVeo(prompt: string): Promise<string> {
  const model = genAI.getGenerativeModel({ model: 'veo-3.1' });

  const result = await model.generateContent({
    contents: [{
      role: 'user',
      parts: [{
        text: `Create a 15-second vertical video (1080x1920) for WhatsApp Status:

${prompt}

Requirements:
- Smooth motion
- Clear text
- Engaging transitions
- Mobile-optimized
`,
      }],
    }],
    generationConfig: {
      responseModalities: ['video'],
      aspectRatio: '9:16',
      duration: 15,
    },
  });

  // Save and return path
  const videoData = result.response.candidates?.[0]?.content?.parts?.find(
    p => p.inlineData?.mimeType === 'video/mp4'
  );

  const outputPath = `./videos/veo-${Date.now()}.mp4`;
  await fs.writeFile(outputPath, Buffer.from(videoData.inlineData.data, 'base64'));

  return outputPath;
}
```

## Batch Video Generation

```typescript
// Generate weekly video content pack
async function generateWeeklyVideos(
  products: Array<{ name: string; imageUrl: string; price: number }>
): Promise<string[]> {
  const generator = new StatusVideoGenerator('./weekly-videos');
  const videos: string[] = [];

  // Monday: New arrivals slideshow
  const mondaySlideshow = await generator.slideshow(
    products.slice(0, 5).map(p => p.imageUrl)
  );
  videos.push(mondaySlideshow);

  // Wednesday: Single product spotlight
  for (const product of products.slice(0, 3)) {
    const spotlight = await generator.kenBurns(product.imageUrl, 8);
    const withText = await generator.addTextOverlay(
      spotlight,
      `${product.name} - KES ${product.price.toLocaleString()}`
    );
    videos.push(withText);
  }

  // Friday: Weekend sale teaser
  // ... generate sale video

  return videos;
}
```

## Video Optimization

```typescript
// Compress for WhatsApp (max 16MB)
async function compressForStatus(inputPath: string): Promise<string> {
  const output = inputPath.replace('.mp4', '-compressed.mp4');

  const cmd = `ffmpeg -y -i "${inputPath}" \
    -c:v libx264 -crf 28 -preset fast \
    -c:a aac -b:a 128k \
    -vf "scale=1080:1920" \
    -fs 15M \
    "${output}"`;

  await execAsync(cmd);
  return output;
}
```

## Best Practices

1. **Keep it short** - 15 seconds is ideal
2. **Hook in 3 seconds** - Grab attention immediately
3. **Text readable** - Large, high contrast text
4. **Silent-friendly** - Many watch without sound
5. **Clear CTA** - End with "DM to Order" or similar
6. **Test on phone** - Always preview on mobile

## Resources

- [Remotion Documentation](https://www.remotion.dev/docs)
- [FFmpeg Filters](https://ffmpeg.org/ffmpeg-filters.html)
- [Veo Model](https://ai.google.dev/gemini-api/docs/video)
