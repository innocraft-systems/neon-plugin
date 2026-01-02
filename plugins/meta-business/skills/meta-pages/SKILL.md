---
name: meta-pages
description: This skill provides guidance for Facebook Pages API integration. Use when the user asks about "Facebook API", "Facebook posting", "FB Page integration", "publish to Facebook", "Facebook business", "page access token", or needs help with posting content, managing comments, or scheduling on Facebook Pages.
---

# Facebook Pages API

Post content, manage engagement, and schedule posts on Facebook Business Pages using the Graph API.

## Base URL

```
https://graph.facebook.com/v21.0
```

## Prerequisites

| Item | Description | How to Get |
|------|-------------|------------|
| Meta Business Account | Business verification | business.facebook.com |
| Facebook App | API access | developers.facebook.com |
| Page Access Token | Long-lived token | OAuth flow or Business Manager |

## Required Permissions

```
pages_manage_posts      # Create/edit/delete posts
pages_read_engagement   # Read comments, reactions
pages_manage_engagement # Reply to comments
pages_read_user_content # Read user posts on page
```

## Authentication

### Get Page Access Token

```typescript
// 1. Get user access token via OAuth
// 2. Exchange for page access token

const response = await fetch(
  `https://graph.facebook.com/v21.0/me/accounts?access_token=${userAccessToken}`
);
const { data } = await response.json();

// Find your page
const page = data.find(p => p.name === 'Martin\'s Electronics');
const pageAccessToken = page.access_token;
const pageId = page.id;
```

### Long-Lived Token

```typescript
// Exchange short-lived token for long-lived (60 days)
const response = await fetch(
  `https://graph.facebook.com/v21.0/oauth/access_token?` +
  `grant_type=fb_exchange_token&` +
  `client_id=${APP_ID}&` +
  `client_secret=${APP_SECRET}&` +
  `fb_exchange_token=${shortLivedToken}`
);

const { access_token } = await response.json();
// This token lasts ~60 days
```

## Posting Content

### Text Post

```bash
POST /{PAGE_ID}/feed
Content-Type: application/json

{
  "message": "New Samsung Galaxy A54 now in stock! Visit our shop on Tom Mboya Street. M-Pesa Till: 123456",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

### Response

```json
{
  "id": "123456789_987654321"
}
```

### Photo Post

```bash
POST /{PAGE_ID}/photos
Content-Type: application/json

{
  "url": "https://shop.example.com/products/samsung-a54.jpg",
  "message": "Samsung Galaxy A54 - KES 45,000\n\nFeatures:\n• 128GB Storage\n• 6GB RAM\n• 5000mAh Battery\n\nDM to order or visit our shop!",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

### Multiple Photos (Album)

```typescript
// Step 1: Upload photos without publishing
const photoIds = await Promise.all(
  imageUrls.map(async (url) => {
    const res = await fetch(
      `https://graph.facebook.com/v21.0/${pageId}/photos`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          url,
          published: false,
          access_token: pageAccessToken,
        }),
      }
    );
    const { id } = await res.json();
    return id;
  })
);

// Step 2: Create post with attached photos
const res = await fetch(
  `https://graph.facebook.com/v21.0/${pageId}/feed`,
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: 'Check out our new arrivals!',
      attached_media: photoIds.map(id => ({ media_fbid: id })),
      access_token: pageAccessToken,
    }),
  }
);
```

### Video Post

```bash
POST /{PAGE_ID}/videos
Content-Type: application/json

{
  "file_url": "https://shop.example.com/videos/promo.mp4",
  "title": "Weekend Sale Preview",
  "description": "Up to 30% off on selected phones this weekend!",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

### Link Post

```bash
POST /{PAGE_ID}/feed
Content-Type: application/json

{
  "message": "Shop our latest products online!",
  "link": "https://martins-electronics.co.ke/products",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

## Scheduling Posts

### Schedule for Later

```bash
POST /{PAGE_ID}/feed
Content-Type: application/json

{
  "message": "Happy Friday! Weekend deals start now 🎉",
  "published": false,
  "scheduled_publish_time": 1705651200,
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

**Note:** `scheduled_publish_time` is Unix timestamp, must be 10 minutes to 6 months in future.

### Get Scheduled Posts

```bash
GET /{PAGE_ID}/scheduled_posts?access_token={PAGE_ACCESS_TOKEN}
```

### Cancel Scheduled Post

```bash
DELETE /{POST_ID}?access_token={PAGE_ACCESS_TOKEN}
```

## Managing Comments

### Get Post Comments

```bash
GET /{POST_ID}/comments?access_token={PAGE_ACCESS_TOKEN}
```

### Reply to Comment

```bash
POST /{COMMENT_ID}/comments
Content-Type: application/json

{
  "message": "Thank you for your interest! Yes, we deliver to Mombasa. DM for details.",
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

### Hide Comment

```bash
POST /{COMMENT_ID}
Content-Type: application/json

{
  "is_hidden": true,
  "access_token": "{PAGE_ACCESS_TOKEN}"
}
```

## Node.js Implementation

```typescript
import axios from 'axios';

interface FacebookConfig {
  pageId: string;
  accessToken: string;
  version?: string;
}

class FacebookPages {
  private config: FacebookConfig;
  private baseUrl: string;

  constructor(config: FacebookConfig) {
    this.config = config;
    this.baseUrl = `https://graph.facebook.com/${config.version || 'v21.0'}`;
  }

  private async request(
    endpoint: string,
    method: 'GET' | 'POST' | 'DELETE' = 'POST',
    data?: object
  ) {
    const response = await axios({
      method,
      url: `${this.baseUrl}${endpoint}`,
      data: {
        ...data,
        access_token: this.config.accessToken,
      },
    });
    return response.data;
  }

  // Post text
  async postText(message: string) {
    return this.request(`/${this.config.pageId}/feed`, 'POST', { message });
  }

  // Post photo
  async postPhoto(imageUrl: string, caption?: string) {
    return this.request(`/${this.config.pageId}/photos`, 'POST', {
      url: imageUrl,
      message: caption,
    });
  }

  // Post multiple photos
  async postPhotos(imageUrls: string[], caption?: string) {
    // Upload unpublished
    const photoIds = await Promise.all(
      imageUrls.map(async (url) => {
        const { id } = await this.request(
          `/${this.config.pageId}/photos`,
          'POST',
          { url, published: false }
        );
        return id;
      })
    );

    // Create post with attachments
    return this.request(`/${this.config.pageId}/feed`, 'POST', {
      message: caption,
      attached_media: photoIds.map(id => ({ media_fbid: id })),
    });
  }

  // Post video
  async postVideo(videoUrl: string, title?: string, description?: string) {
    return this.request(`/${this.config.pageId}/videos`, 'POST', {
      file_url: videoUrl,
      title,
      description,
    });
  }

  // Post link
  async postLink(link: string, message?: string) {
    return this.request(`/${this.config.pageId}/feed`, 'POST', {
      link,
      message,
    });
  }

  // Schedule post
  async schedulePost(message: string, publishTime: Date, imageUrl?: string) {
    const timestamp = Math.floor(publishTime.getTime() / 1000);

    if (imageUrl) {
      // Upload photo unpublished
      const { id: photoId } = await this.request(
        `/${this.config.pageId}/photos`,
        'POST',
        { url: imageUrl, published: false }
      );

      return this.request(`/${this.config.pageId}/feed`, 'POST', {
        message,
        attached_media: [{ media_fbid: photoId }],
        published: false,
        scheduled_publish_time: timestamp,
      });
    }

    return this.request(`/${this.config.pageId}/feed`, 'POST', {
      message,
      published: false,
      scheduled_publish_time: timestamp,
    });
  }

  // Get scheduled posts
  async getScheduledPosts() {
    return this.request(
      `/${this.config.pageId}/scheduled_posts`,
      'GET'
    );
  }

  // Get post comments
  async getComments(postId: string) {
    return this.request(`/${postId}/comments`, 'GET');
  }

  // Reply to comment
  async replyToComment(commentId: string, message: string) {
    return this.request(`/${commentId}/comments`, 'POST', { message });
  }

  // Delete post
  async deletePost(postId: string) {
    return this.request(`/${postId}`, 'DELETE');
  }
}

// Usage
const facebook = new FacebookPages({
  pageId: process.env.FB_PAGE_ID!,
  accessToken: process.env.FB_PAGE_ACCESS_TOKEN!,
});

// Post product announcement
await facebook.postPhoto(
  'https://shop.example.com/products/samsung-a54.jpg',
  `New Arrival: Samsung Galaxy A54

KES 45,000

Features:
• 128GB Storage
• 6GB RAM
• 5000mAh Battery
• Super AMOLED Display

📍 Tom Mboya Street, Nairobi
📱 M-Pesa Till: 123456
💬 DM to order

#SamsungKenya #MartinsElectronics #Nairobi`
);

// Schedule weekend sale post
await facebook.schedulePost(
  '🎉 WEEKEND SALE STARTS NOW!\n\nUp to 30% off on selected phones.\nVisit us today!',
  new Date('2024-01-19T09:00:00+03:00'), // Friday 9am EAT
  'https://shop.example.com/banners/weekend-sale.jpg'
);
```

## Multi-Tenant Architecture

```typescript
interface TenantFacebookConfig {
  tenantId: string;
  pageId: string;
  pageName: string;
  accessTokenEncrypted: string;
  tokenExpiresAt: Date;
}

// Create client for tenant
async function createTenantFacebookClient(tenant: TenantFacebookConfig) {
  // Check token expiry
  if (tenant.tokenExpiresAt < new Date()) {
    throw new Error('Facebook token expired, needs refresh');
  }

  return new FacebookPages({
    pageId: tenant.pageId,
    accessToken: await decrypt(tenant.accessTokenEncrypted),
  });
}

// OAuth callback to save tenant's page connection
async function handleFacebookOAuth(tenantId: string, code: string) {
  // Exchange code for user token
  const userToken = await exchangeCodeForToken(code);

  // Get pages the user manages
  const pages = await getPages(userToken);

  // Let user select which page to connect
  // Save page ID and page access token (encrypted)
  await saveTenantFacebookConfig(tenantId, {
    pageId: pages[0].id,
    pageName: pages[0].name,
    accessToken: pages[0].access_token,
  });
}
```

## Best Practices

1. **Use long-lived tokens** - Refresh before 60-day expiry
2. **Handle rate limits** - 200 calls/user/hour for most endpoints
3. **Include hashtags** - Improves discoverability
4. **Optimal posting times** - Kenya: 7-9am, 12-2pm, 7-9pm
5. **Respond to comments** - Improves engagement metrics
6. **Use Call-to-Action** - "DM to order", "Visit our shop", Till numbers

## Error Codes

| Code | Description | Solution |
|------|-------------|----------|
| 190 | Invalid access token | Refresh or re-authenticate |
| 200 | Permission denied | Check app permissions |
| 368 | Temporarily blocked | Reduce posting frequency |
| 100 | Invalid parameter | Check request format |

## Resources

- [Pages API Reference](https://developers.facebook.com/docs/pages-api)
- [Graph API Explorer](https://developers.facebook.com/tools/explorer)
