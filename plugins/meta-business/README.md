# Meta Business Plugin

Facebook Pages and Instagram Business API integration for Claude Code.

## Features

- **Facebook Pages** - Post text, photos, videos, links; schedule posts; manage comments
- **Instagram Business** - Post images, carousels, reels, stories
- **Insights & Analytics** - Track performance, engagement, follower growth

## Skills

### meta-pages
- Text, photo, video, and link posting
- Multi-photo posts (albums)
- Post scheduling
- Comment management
- Long-lived token handling

### meta-instagram
- Single image posts
- Carousel posts (2-10 images)
- Reels (video)
- Stories
- Caption and hashtag best practices

### meta-insights
- Page-level metrics (impressions, reach, engagement)
- Post performance tracking
- Instagram account insights
- Media performance analysis
- Best posting times detection

## Quick Start

### Environment Variables

```bash
FB_PAGE_ID=your_page_id
FB_PAGE_ACCESS_TOKEN=your_page_access_token
IG_ACCOUNT_ID=your_ig_business_account_id
```

### Post to Facebook

```typescript
const facebook = new FacebookPages({
  pageId: process.env.FB_PAGE_ID!,
  accessToken: process.env.FB_PAGE_ACCESS_TOKEN!,
});

await facebook.postPhoto(
  'https://example.com/product.jpg',
  'New product now available! DM to order.'
);
```

### Post to Instagram

```typescript
const instagram = new InstagramBusiness({
  igAccountId: process.env.IG_ACCOUNT_ID!,
  accessToken: process.env.FB_PAGE_ACCESS_TOKEN!,
});

await instagram.postCarousel(
  ['image1.jpg', 'image2.jpg', 'image3.jpg'],
  'Swipe to see all! #NewArrivals'
);
```

## Prerequisites

1. Meta Business Account
2. Facebook Page (for both FB and IG)
3. Instagram Business Account connected to Page
4. Meta App with required permissions

## Resources

- [Facebook Pages API](https://developers.facebook.com/docs/pages-api)
- [Instagram Content Publishing](https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/content-publishing)
