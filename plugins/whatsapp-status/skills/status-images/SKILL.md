---
name: status-images
description: This skill provides guidance for generating WhatsApp Status images using Nano Banana (Gemini image generation). Use when the user asks about "status image", "WhatsApp status template", "product image generator", "promo banner", "Nano Banana", "AI image generation", "status template", or needs help creating professional images for WhatsApp Status.
---

# WhatsApp Status Image Generation

Generate professional Status-ready images using Nano Banana (Gemini's image generation API). Create product showcases, promo banners, price lists, and more.

## Nano Banana Overview

Nano Banana is Google's Gemini-based image generation:

| Model | ID | Best For |
|-------|-----|----------|
| **Nano Banana** | `gemini-2.5-flash-image` | Fast generation, batch processing |
| **Nano Banana Pro** | `gemini-3-pro-image-preview` | High-fidelity, text rendering |

## Status Image Dimensions

```
Width:  1080px
Height: 1920px
Ratio:  9:16 (portrait)
```

## Setup

### Install SDK

```bash
npm install @google/generative-ai
```

### Environment Variables

```bash
GOOGLE_API_KEY=your_gemini_api_key
```

## Nano Banana API

### Basic Image Generation

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY!);

async function generateStatusImage(prompt: string): Promise<Buffer> {
  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash-image',
  });

  const result = await model.generateContent({
    contents: [{
      role: 'user',
      parts: [{
        text: prompt,
      }],
    }],
    generationConfig: {
      responseModalities: ['image'],
      // Status dimensions
      imageDimensions: {
        width: 1080,
        height: 1920,
      },
    },
  });

  const image = result.response.candidates?.[0]?.content?.parts?.find(
    p => p.inlineData
  );

  if (!image?.inlineData) {
    throw new Error('No image generated');
  }

  return Buffer.from(image.inlineData.data, 'base64');
}
```

### Nano Banana Pro (High Quality)

```typescript
async function generateProStatusImage(prompt: string): Promise<Buffer> {
  const model = genAI.getGenerativeModel({
    model: 'gemini-3-pro-image-preview',
  });

  const result = await model.generateContent({
    contents: [{
      role: 'user',
      parts: [{
        text: `Create a professional WhatsApp Status image (1080x1920, 9:16 portrait):

${prompt}

Style: Modern, clean, high contrast, mobile-optimized text
`,
      }],
    }],
    generationConfig: {
      responseModalities: ['image'],
    },
  });

  const image = result.response.candidates?.[0]?.content?.parts?.find(
    p => p.inlineData
  );

  return Buffer.from(image.inlineData.data, 'base64');
}
```

## Status Template Prompts

### Product Showcase

```typescript
const productShowcasePrompt = (product: {
  name: string;
  price: string;
  features: string[];
  imageDescription: string;
}) => `
Create a WhatsApp Status image for a product showcase:

Product: ${product.name}
Price: KES ${product.price}
Features: ${product.features.join(', ')}

Visual: ${product.imageDescription}

Style:
- Modern, clean design
- Price prominently displayed in KES
- Dark gradient background
- Product image centered
- "DM to Order" call-to-action at bottom
- M-Pesa logo small in corner
`;

// Usage
const image = await generateProStatusImage(
  productShowcasePrompt({
    name: 'Samsung Galaxy A54',
    price: '45,000',
    features: ['128GB', '6GB RAM', '5000mAh Battery'],
    imageDescription: 'Modern smartphone on elegant display stand',
  })
);
```

### Flash Sale Banner

```typescript
const flashSalePrompt = (sale: {
  discount: string;
  endTime: string;
  products: string;
}) => `
Create an urgent WhatsApp Status flash sale banner:

Discount: ${sale.discount}% OFF
Ends: ${sale.endTime}
Products: ${sale.products}

Style:
- Bold red/orange gradient background
- Large "FLASH SALE" text
- Countdown timer visual
- "Limited Stock" urgency element
- Swipe up arrow at bottom
- Exciting, energetic mood
`;

const saleImage = await generateProStatusImage(
  flashSalePrompt({
    discount: '30',
    endTime: 'Tonight 9PM',
    products: 'All Samsung Phones',
  })
);
```

### New Arrival

```typescript
const newArrivalPrompt = (product: {
  name: string;
  tagline: string;
}) => `
Create a "New Arrival" WhatsApp Status announcement:

Product: ${product.name}
Tagline: ${product.tagline}

Style:
- Elegant, premium feel
- "NEW" badge in corner
- Subtle sparkle effects
- Dark luxury background
- Clean typography
- "Now Available" text
`;
```

### Price List

```typescript
const priceListPrompt = (items: Array<{ name: string; price: string }>) => `
Create a WhatsApp Status price list:

Items:
${items.map(i => `- ${i.name}: KES ${i.price}`).join('\n')}

Style:
- Clean, organized layout
- Prices right-aligned
- Business logo placeholder at top
- Contact info at bottom
- Easy to read on mobile
- Professional, trustworthy design
`;
```

### Testimonial Card

```typescript
const testimonialPrompt = (testimonial: {
  quote: string;
  customerName: string;
  product: string;
}) => `
Create a customer testimonial WhatsApp Status:

Quote: "${testimonial.quote}"
Customer: ${testimonial.customerName}
Product: ${testimonial.product}

Style:
- Quote marks design element
- Customer avatar placeholder
- 5-star rating visual
- Soft, trustworthy colors
- "Real Customer Review" label
`;
```

### Back in Stock

```typescript
const backInStockPrompt = (product: {
  name: string;
  previouslyWaitlisted: boolean;
}) => `
Create a "Back in Stock" WhatsApp Status alert:

Product: ${product.name}

Style:
- Green "BACK IN STOCK" badge
- Product image prominent
- "Limited Quantity" warning
- "Order Now" call-to-action
- Celebration confetti subtle effect
`;
```

## Node.js Implementation

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';
import sharp from 'sharp';
import fs from 'fs/promises';

interface StatusImageConfig {
  apiKey: string;
  outputDir: string;
  usePro?: boolean;
}

class StatusImageGenerator {
  private genAI: GoogleGenerativeAI;
  private config: StatusImageConfig;

  constructor(config: StatusImageConfig) {
    this.genAI = new GoogleGenerativeAI(config.apiKey);
    this.config = config;
  }

  private getModel() {
    return this.genAI.getGenerativeModel({
      model: this.config.usePro
        ? 'gemini-3-pro-image-preview'
        : 'gemini-2.5-flash-image',
    });
  }

  async generate(prompt: string, filename: string): Promise<string> {
    const model = this.getModel();

    const result = await model.generateContent({
      contents: [{
        role: 'user',
        parts: [{
          text: `Create a WhatsApp Status image (1080x1920, 9:16 portrait format):

${prompt}

Requirements:
- Optimized for mobile viewing
- High contrast text
- Clear call-to-action
- Professional design
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

    if (!imagePart?.inlineData) {
      throw new Error('Image generation failed');
    }

    const buffer = Buffer.from(imagePart.inlineData.data, 'base64');

    // Ensure correct dimensions with Sharp
    const resized = await sharp(buffer)
      .resize(1080, 1920, { fit: 'cover' })
      .jpeg({ quality: 90 })
      .toBuffer();

    const filepath = `${this.config.outputDir}/${filename}`;
    await fs.writeFile(filepath, resized);

    return filepath;
  }

  // Product showcase
  async productShowcase(product: {
    name: string;
    price: number;
    features: string[];
    description: string;
  }): Promise<string> {
    const prompt = `
Product showcase for ${product.name}

Price: KES ${product.price.toLocaleString()}
Features: ${product.features.join(' | ')}

Visual: ${product.description}

Include:
- Product image centered
- Price in bold
- "DM to Order" button
- M-Pesa accepted badge
`;

    return this.generate(prompt, `product-${Date.now()}.jpg`);
  }

  // Flash sale
  async flashSale(sale: {
    discount: number;
    endTime: string;
    category: string;
  }): Promise<string> {
    const prompt = `
FLASH SALE banner - URGENT style

${sale.discount}% OFF on ${sale.category}
Ends: ${sale.endTime}

Style: Red/orange urgent colors, countdown visual, "LIMITED TIME" text
`;

    return this.generate(prompt, `sale-${Date.now()}.jpg`);
  }

  // New arrival
  async newArrival(product: {
    name: string;
    tagline: string;
  }): Promise<string> {
    const prompt = `
NEW ARRIVAL announcement

Product: ${product.name}
"${product.tagline}"

Style: Elegant, premium, "NEW" badge, sparkle effects
`;

    return this.generate(prompt, `new-${Date.now()}.jpg`);
  }

  // Testimonial
  async testimonial(review: {
    quote: string;
    customer: string;
    rating: number;
  }): Promise<string> {
    const stars = '★'.repeat(review.rating) + '☆'.repeat(5 - review.rating);
    const prompt = `
Customer testimonial card

"${review.quote}"
- ${review.customer}
Rating: ${stars}

Style: Trustworthy, quote marks design, avatar placeholder
`;

    return this.generate(prompt, `review-${Date.now()}.jpg`);
  }

  // Price list
  async priceList(
    businessName: string,
    items: Array<{ name: string; price: number }>
  ): Promise<string> {
    const itemsList = items
      .map(i => `${i.name} - KES ${i.price.toLocaleString()}`)
      .join('\n');

    const prompt = `
Price list for ${businessName}

${itemsList}

Style: Clean, organized, professional, prices aligned right
Contact info at bottom
`;

    return this.generate(prompt, `prices-${Date.now()}.jpg`);
  }

  // M-Pesa payment accepted
  async mpesaAccepted(tillNumber: string): Promise<string> {
    const prompt = `
M-Pesa payment accepted badge/banner

Till Number: ${tillNumber}

Style: Safaricom green colors, M-Pesa logo style, "Pay via M-Pesa" text
Easy to read till number prominently displayed
`;

    return this.generate(prompt, `mpesa-${Date.now()}.jpg`);
  }
}

// Usage
const generator = new StatusImageGenerator({
  apiKey: process.env.GOOGLE_API_KEY!,
  outputDir: './status-images',
  usePro: true, // Use Nano Banana Pro for better quality
});

// Generate product showcase
const productImage = await generator.productShowcase({
  name: 'Samsung Galaxy A54',
  price: 45000,
  features: ['128GB', '6GB RAM', '5000mAh'],
  description: 'Sleek smartphone with vibrant display',
});
console.log('Product image saved:', productImage);

// Generate flash sale
const saleImage = await generator.flashSale({
  discount: 30,
  endTime: 'Sunday 9PM',
  category: 'All Phones',
});
console.log('Sale image saved:', saleImage);
```

## Kenya-Specific Templates

### M-Pesa Till Badge

```typescript
const mpesaTillPrompt = (tillNumber: string) => `
Create an M-Pesa payment instruction Status:

Till Number: ${tillNumber}

Include:
- Safaricom green color theme
- M-Pesa logo style (if possible, or text "M-PESA")
- "Lipa Na M-Pesa" text
- Till number VERY prominent
- Simple step instructions: "Go to M-Pesa → Lipa na M-Pesa → Till Number"
`;
```

### Delivery Areas

```typescript
const deliveryAreasPrompt = (areas: string[]) => `
Create a delivery areas Status:

We Deliver To:
${areas.map(a => `• ${a}`).join('\n')}

Style:
- Map pin icons
- Clean list format
- "Free Delivery" badge if applicable
- "Order via WhatsApp" at bottom
`;
```

### Business Hours

```typescript
const businessHoursPrompt = (hours: {
  weekdays: string;
  saturday: string;
  sunday: string;
}) => `
Create business hours Status:

Monday - Friday: ${hours.weekdays}
Saturday: ${hours.saturday}
Sunday: ${hours.sunday}

Style:
- Clock icon
- Clean, readable layout
- Location pin with address
- "Visit Us Today" call-to-action
`;
```

## Batch Generation

```typescript
// Generate weekly content pack
async function generateWeeklyPack(
  generator: StatusImageGenerator,
  products: Array<{ name: string; price: number; description: string }>
) {
  const images = [];

  for (const product of products) {
    const image = await generator.productShowcase({
      name: product.name,
      price: product.price,
      features: [],
      description: product.description,
    });
    images.push(image);

    // Rate limit: wait between generations
    await new Promise(r => setTimeout(r, 2000));
  }

  return images;
}
```

## Image Post-Processing

```typescript
import sharp from 'sharp';

// Add watermark/logo
async function addWatermark(
  imagePath: string,
  logoPath: string
): Promise<Buffer> {
  const logo = await sharp(logoPath)
    .resize(150, 150, { fit: 'inside' })
    .toBuffer();

  return sharp(imagePath)
    .composite([{
      input: logo,
      gravity: 'southeast',
      blend: 'over',
    }])
    .toBuffer();
}

// Add text overlay
async function addTextOverlay(
  imagePath: string,
  text: string
): Promise<Buffer> {
  const svgText = `
    <svg width="1080" height="200">
      <style>
        .title { fill: white; font-size: 48px; font-family: Arial; }
      </style>
      <text x="50%" y="50%" class="title" text-anchor="middle">${text}</text>
    </svg>
  `;

  return sharp(imagePath)
    .composite([{
      input: Buffer.from(svgText),
      gravity: 'south',
    }])
    .toBuffer();
}
```

## Best Practices

1. **High contrast** - Status is viewed quickly, text must pop
2. **One message** - Don't overload with information
3. **Clear CTA** - "DM to Order", "Swipe Up", etc.
4. **Brand colors** - Consistent look across all Status
5. **Mobile-first** - Test on actual phone before posting
6. **Price prominent** - Kenyans want to know cost immediately

## Rate Limits

| Model | Requests/Min | Images/Day |
|-------|--------------|------------|
| Flash | 15 | 1,500 |
| Pro | 5 | 100 |

## Resources

- [Gemini Image Generation](https://ai.google.dev/gemini-api/docs/image-generation)
- [Nano Banana Pro](https://ai.google.dev/gemini-api/docs/nanobanana)
