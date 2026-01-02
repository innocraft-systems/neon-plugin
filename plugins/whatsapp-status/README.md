# WhatsApp Status Plugin

AI-powered content generation and scheduling for WhatsApp Status. Create professional images and videos using Nano Banana (Gemini) and schedule posting reminders.

**Note:** WhatsApp Status cannot be automated via API. This plugin generates content and sends reminders to business owners who then post manually.

## Features

- **AI Image Generation** - Product showcases, promo banners, price lists using Nano Banana
- **Video Creation** - Slideshows, animations using Veo/FFmpeg/Remotion
- **Smart Scheduling** - Optimal posting times for Kenya market
- **Reminder System** - WhatsApp, SMS, Push notifications

## Skills

### status-images
- Nano Banana (Gemini 2.5 Flash Image) integration
- Nano Banana Pro (Gemini 3 Pro Image) for high quality
- Product showcase templates
- Flash sale banners
- Price lists
- Testimonial cards
- M-Pesa payment badges

### status-videos
- Veo video generation
- FFmpeg slideshows
- Remotion programmatic videos
- Ken Burns effects
- Text overlays

### status-scheduler
- Content calendar management
- Kenya-optimized posting times
- Multi-channel reminders (WhatsApp, SMS, Push)
- Weekly content pack generation
- Performance analytics

## Quick Start

### Generate Product Image

```typescript
const generator = new StatusImageGenerator({
  apiKey: process.env.GOOGLE_API_KEY!,
  outputDir: './status-images',
  usePro: true,
});

const image = await generator.productShowcase({
  name: 'Samsung Galaxy A54',
  price: 45000,
  features: ['128GB', '6GB RAM'],
  description: 'Sleek smartphone',
});
```

### Schedule Content

```typescript
const scheduler = new StatusScheduler(config);

await scheduler.scheduleContent(
  tenantId,
  { type: 'image', filePath: image, caption: 'New arrival!' },
  new Date('2024-01-20T09:00:00+03:00')
);
```

## Environment Variables

```bash
GOOGLE_API_KEY=your_gemini_api_key
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
```

## Resources

- [Nano Banana API](https://ai.google.dev/gemini-api/docs/image-generation)
- [Remotion](https://www.remotion.dev/)
