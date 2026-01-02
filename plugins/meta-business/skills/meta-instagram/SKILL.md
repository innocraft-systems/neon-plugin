---
name: meta-instagram
description: This skill provides guidance for Instagram Business API integration. Use when the user asks about "Instagram API", "Instagram posting", "IG business", "publish to Instagram", "Instagram reels", "carousel post", "Instagram story API", or needs help with posting images, videos, or carousels to Instagram Business accounts.
---

# Instagram Business API

Post images, carousels, reels, and stories to Instagram Business accounts via the Content Publishing API.

## Base URL

```
https://graph.facebook.com/v21.0
```

## Prerequisites

| Item | Description | Required |
|------|-------------|----------|
| Instagram Business Account | Not personal/creator | Yes |
| Connected Facebook Page | Page linked to IG | Yes |
| Meta Business Account | For API access | Yes |
| Page Access Token | With IG permissions | Yes |

**Important:** Instagram API only works with **Business** accounts connected to a Facebook Page.

## Required Permissions

```
instagram_basic              # Read IG profile
instagram_content_publish    # Create posts
pages_read_engagement        # Required dependency
```

## Get Instagram Account ID

```typescript
// Get IG account linked to your Facebook Page
const response = await fetch(
  `https://graph.facebook.com/v21.0/${pageId}?` +
  `fields=instagram_business_account&` +
  `access_token=${pageAccessToken}`
);

const { instagram_business_account } = await response.json();
const igAccountId = instagram_business_account.id;
```

## Content Publishing Flow

Instagram uses a **two-step** publishing process:

1. **Create container** - Upload media, get container ID
2. **Publish container** - Make it live

## Single Image Post

### Step 1: Create Container

```bash
POST /{IG_ACCOUNT_ID}/media
Content-Type: application/json

{
  "image_url": "https://shop.example.com/products/samsung-a54.jpg",
  "caption": "Samsung Galaxy A54 - KES 45,000\n\n✨ Features:\n• 128GB Storage\n• 6GB RAM\n• 5000mAh Battery\n\n📍 Tom Mboya Street\n💳 M-Pesa Till: 123456\n📱 DM to order\n\n#SamsungKenya #Nairobi #MartinsElectronics",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

**Response:**
```json
{
  "id": "17889455560051444"
}
```

### Step 2: Publish

```bash
POST /{IG_ACCOUNT_ID}/media_publish
Content-Type: application/json

{
  "creation_id": "17889455560051444",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

**Response:**
```json
{
  "id": "17920238751030545"
}
```

## Carousel Post (Multiple Images)

### Step 1: Create Item Containers

```typescript
// Create container for each image (max 10)
const itemIds = await Promise.all(
  imageUrls.map(async (url) => {
    const res = await fetch(
      `https://graph.facebook.com/v21.0/${igAccountId}/media`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          image_url: url,
          is_carousel_item: true,
          access_token: pageAccessToken,
        }),
      }
    );
    const { id } = await res.json();
    return id;
  })
);
```

### Step 2: Create Carousel Container

```bash
POST /{IG_ACCOUNT_ID}/media
Content-Type: application/json

{
  "media_type": "CAROUSEL",
  "children": ["17889455560051444", "17889455560051445", "17889455560051446"],
  "caption": "New arrivals this week! Swipe to see all →\n\n#NewArrivals #MartinsElectronics",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

### Step 3: Publish Carousel

```bash
POST /{IG_ACCOUNT_ID}/media_publish
Content-Type: application/json

{
  "creation_id": "{CAROUSEL_CONTAINER_ID}",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

## Reels (Video)

### Create Reel Container

```bash
POST /{IG_ACCOUNT_ID}/media
Content-Type: application/json

{
  "media_type": "REELS",
  "video_url": "https://shop.example.com/videos/product-demo.mp4",
  "caption": "Check out the Samsung A54 camera quality! 📸\n\n#SamsungA54 #PhoneReview #Kenya",
  "share_to_feed": true,
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

### Check Upload Status

Reels require processing. Poll until ready:

```typescript
async function waitForMediaReady(containerId: string): Promise<boolean> {
  const maxAttempts = 30;
  const delayMs = 5000;

  for (let i = 0; i < maxAttempts; i++) {
    const res = await fetch(
      `https://graph.facebook.com/v21.0/${containerId}?` +
      `fields=status_code&access_token=${pageAccessToken}`
    );
    const { status_code } = await res.json();

    if (status_code === 'FINISHED') return true;
    if (status_code === 'ERROR') return false;

    await sleep(delayMs);
  }

  return false;
}
```

### Publish Reel

```bash
POST /{IG_ACCOUNT_ID}/media_publish
Content-Type: application/json

{
  "creation_id": "{REEL_CONTAINER_ID}",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

## Stories

Stories require different approach - they're posted via the same API but with `media_type: STORIES`:

```bash
POST /{IG_ACCOUNT_ID}/media
Content-Type: application/json

{
  "media_type": "STORIES",
  "image_url": "https://shop.example.com/stories/flash-sale.jpg",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

**Note:** Story dimensions should be 1080x1920 (9:16 aspect ratio).

## Node.js Implementation

```typescript
import axios from 'axios';

interface InstagramConfig {
  igAccountId: string;
  accessToken: string;
  version?: string;
}

class InstagramBusiness {
  private config: InstagramConfig;
  private baseUrl: string;

  constructor(config: InstagramConfig) {
    this.config = config;
    this.baseUrl = `https://graph.facebook.com/${config.version || 'v21.0'}`;
  }

  private async request(endpoint: string, data?: object) {
    const response = await axios.post(`${this.baseUrl}${endpoint}`, {
      ...data,
      access_token: this.config.accessToken,
    });
    return response.data;
  }

  private async createContainer(params: object) {
    return this.request(`/${this.config.igAccountId}/media`, params);
  }

  private async publish(containerId: string) {
    return this.request(`/${this.config.igAccountId}/media_publish`, {
      creation_id: containerId,
    });
  }

  private async waitForReady(containerId: string, maxWaitMs = 120000) {
    const startTime = Date.now();

    while (Date.now() - startTime < maxWaitMs) {
      const res = await axios.get(
        `${this.baseUrl}/${containerId}?fields=status_code&access_token=${this.config.accessToken}`
      );

      if (res.data.status_code === 'FINISHED') return true;
      if (res.data.status_code === 'ERROR') {
        throw new Error('Media processing failed');
      }

      await new Promise(r => setTimeout(r, 5000));
    }

    throw new Error('Media processing timeout');
  }

  // Post single image
  async postImage(imageUrl: string, caption: string) {
    const { id: containerId } = await this.createContainer({
      image_url: imageUrl,
      caption,
    });

    return this.publish(containerId);
  }

  // Post carousel
  async postCarousel(imageUrls: string[], caption: string) {
    if (imageUrls.length < 2 || imageUrls.length > 10) {
      throw new Error('Carousel requires 2-10 images');
    }

    // Create item containers
    const itemIds = await Promise.all(
      imageUrls.map(async (url) => {
        const { id } = await this.createContainer({
          image_url: url,
          is_carousel_item: true,
        });
        return id;
      })
    );

    // Create carousel container
    const { id: carouselId } = await this.createContainer({
      media_type: 'CAROUSEL',
      children: itemIds,
      caption,
    });

    return this.publish(carouselId);
  }

  // Post reel
  async postReel(
    videoUrl: string,
    caption: string,
    shareToFeed = true
  ) {
    const { id: containerId } = await this.createContainer({
      media_type: 'REELS',
      video_url: videoUrl,
      caption,
      share_to_feed: shareToFeed,
    });

    // Wait for processing
    await this.waitForReady(containerId);

    return this.publish(containerId);
  }

  // Post story
  async postStory(imageUrl: string) {
    const { id: containerId } = await this.createContainer({
      media_type: 'STORIES',
      image_url: imageUrl,
    });

    return this.publish(containerId);
  }

  // Get account info
  async getAccountInfo() {
    const res = await axios.get(
      `${this.baseUrl}/${this.config.igAccountId}?` +
      `fields=username,followers_count,media_count&` +
      `access_token=${this.config.accessToken}`
    );
    return res.data;
  }
}

// Usage
const instagram = new InstagramBusiness({
  igAccountId: process.env.IG_ACCOUNT_ID!,
  accessToken: process.env.FB_PAGE_ACCESS_TOKEN!,
});

// Post product image
await instagram.postImage(
  'https://shop.example.com/products/samsung-a54.jpg',
  `Samsung Galaxy A54 - KES 45,000 ✨

Features:
• 128GB Storage
• 6GB RAM
• 5000mAh Battery
• Super AMOLED Display

📍 Tom Mboya Street, Nairobi
📱 M-Pesa Till: 123456
💬 DM to order!

#SamsungKenya #Nairobi #PhoneShop #MartinsElectronics`
);

// Post product carousel
await instagram.postCarousel(
  [
    'https://shop.example.com/products/a54-front.jpg',
    'https://shop.example.com/products/a54-back.jpg',
    'https://shop.example.com/products/a54-camera.jpg',
  ],
  `Samsung A54 from every angle 📱

Swipe → to see all views

KES 45,000 | DM to order

#Samsung #A54 #Kenya`
);

// Post product reel
await instagram.postReel(
  'https://shop.example.com/videos/a54-unboxing.mp4',
  `Unboxing the Samsung Galaxy A54! 📦

Watch till the end for the camera test 📸

Available now at Martin's Electronics
KES 45,000

#Unboxing #Samsung #Kenya`
);
```

## Image Requirements

| Type | Dimensions | Aspect Ratio | Max Size |
|------|------------|--------------|----------|
| Feed Post | 1080x1080 | 1:1 (square) | 8MB |
| Portrait | 1080x1350 | 4:5 | 8MB |
| Landscape | 1080x566 | 1.91:1 | 8MB |
| Story | 1080x1920 | 9:16 | 8MB |
| Carousel | Same as feed | Mixed allowed | 8MB each |

## Video Requirements

| Type | Dimensions | Duration | Max Size |
|------|------------|----------|----------|
| Reel | 1080x1920 | 3s-15min | 1GB |
| Story | 1080x1920 | Up to 60s | 100MB |

## Caption Best Practices

```typescript
const caption = `
${headline}

${productDetails}

${callToAction}

${hashtags}
`.trim();

// Example
const productCaption = `
Samsung Galaxy A54 - KES 45,000 🔥

✨ 128GB Storage
✨ 6GB RAM
✨ 5000mAh Battery

📍 Tom Mboya Street, Nairobi
📱 M-Pesa Till: 123456
💬 DM to order!

#SamsungKenya #PhoneShop #Nairobi #MartinsElectronics #TechKenya
`.trim();
```

### Hashtag Strategy

```typescript
const hashtags = {
  // Product specific
  product: ['#SamsungA54', '#Samsung', '#AndroidPhone'],

  // Location
  location: ['#Nairobi', '#Kenya', '#EastAfrica'],

  // Business
  business: ['#MartinsElectronics', '#PhoneShop', '#TechStore'],

  // Trending
  trending: ['#NewArrivals', '#InStock', '#ShopLocal'],
};

// Use 5-10 relevant hashtags, not 30 spam ones
```

## Multi-Tenant Setup

```typescript
interface TenantInstagramConfig {
  tenantId: string;
  igAccountId: string;
  igUsername: string;
  pageId: string; // Connected FB Page
  accessTokenEncrypted: string;
}

async function getInstagramAccountForTenant(
  tenantId: string
): Promise<InstagramBusiness> {
  const config = await db.getTenantInstagramConfig(tenantId);

  return new InstagramBusiness({
    igAccountId: config.igAccountId,
    accessToken: await decrypt(config.accessTokenEncrypted),
  });
}

// During OAuth setup
async function linkInstagramAccount(tenantId: string, pageId: string) {
  const pageAccessToken = await getPageAccessToken(tenantId, pageId);

  // Get linked IG account
  const res = await fetch(
    `https://graph.facebook.com/v21.0/${pageId}?` +
    `fields=instagram_business_account{id,username}&` +
    `access_token=${pageAccessToken}`
  );

  const { instagram_business_account } = await res.json();

  if (!instagram_business_account) {
    throw new Error('No Instagram Business account linked to this Page');
  }

  await db.saveTenantInstagramConfig(tenantId, {
    igAccountId: instagram_business_account.id,
    igUsername: instagram_business_account.username,
    pageId,
  });
}
```

## Error Handling

```typescript
try {
  await instagram.postImage(imageUrl, caption);
} catch (error) {
  if (axios.isAxiosError(error)) {
    const fbError = error.response?.data?.error;

    switch (fbError?.code) {
      case 9:
        // Rate limited
        console.log('Rate limited, retry after:', fbError.message);
        break;
      case 36003:
        // Image URL not accessible
        console.log('Cannot fetch image from URL');
        break;
      case 2207026:
        // Caption contains blocked content
        console.log('Caption violates guidelines');
        break;
      default:
        console.error('Instagram error:', fbError?.message);
    }
  }
}
```

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| Content Publishing | 25 posts/day per account |
| API calls | 200/user/hour |

## Resources

- [Content Publishing API](https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/content-publishing)
- [Instagram Graph API](https://developers.facebook.com/docs/instagram-platform/instagram-graph-api)
