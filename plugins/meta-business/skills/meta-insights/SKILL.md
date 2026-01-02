---
name: meta-insights
description: This skill provides guidance for Meta analytics and insights APIs. Use when the user asks about "Facebook analytics", "Instagram insights", "page metrics", "post performance", "engagement stats", "social media analytics", "reach impressions", or needs help with tracking content performance on Facebook or Instagram.
---

# Meta Business Insights

Track performance metrics for Facebook Pages and Instagram Business accounts using the Insights API.

## Base URL

```
https://graph.facebook.com/v21.0
```

## Required Permissions

```
pages_read_engagement    # Page insights
instagram_basic          # IG account info
read_insights            # Detailed metrics
```

## Facebook Page Insights

### Page-Level Metrics

```bash
GET /{PAGE_ID}/insights?metric=page_impressions,page_engaged_users,page_fans&period=day&access_token={TOKEN}
```

### Available Page Metrics

| Metric | Description | Periods |
|--------|-------------|---------|
| `page_impressions` | Total views of page content | day, week, days_28 |
| `page_engaged_users` | Unique users who engaged | day, week, days_28 |
| `page_fans` | Total page likes | day |
| `page_fan_adds` | New likes | day |
| `page_fan_removes` | Unlikes | day |
| `page_views_total` | Page profile views | day |
| `page_post_engagements` | Post interactions | day, week, days_28 |

### Get Page Insights

```typescript
interface PageInsights {
  impressions: number;
  reach: number;
  engagedUsers: number;
  totalFans: number;
  newFans: number;
}

async function getPageInsights(
  pageId: string,
  accessToken: string,
  period: 'day' | 'week' | 'days_28' = 'day'
): Promise<PageInsights> {
  const metrics = [
    'page_impressions',
    'page_engaged_users',
    'page_fans',
    'page_fan_adds',
  ].join(',');

  const res = await fetch(
    `https://graph.facebook.com/v21.0/${pageId}/insights?` +
    `metric=${metrics}&period=${period}&access_token=${accessToken}`
  );

  const { data } = await res.json();

  return {
    impressions: data.find(m => m.name === 'page_impressions')?.values[0]?.value || 0,
    reach: data.find(m => m.name === 'page_impressions_unique')?.values[0]?.value || 0,
    engagedUsers: data.find(m => m.name === 'page_engaged_users')?.values[0]?.value || 0,
    totalFans: data.find(m => m.name === 'page_fans')?.values[0]?.value || 0,
    newFans: data.find(m => m.name === 'page_fan_adds')?.values[0]?.value || 0,
  };
}
```

## Post Insights

### Get Post Metrics

```bash
GET /{POST_ID}/insights?metric=post_impressions,post_engaged_users,post_clicks&access_token={TOKEN}
```

### Available Post Metrics

| Metric | Description |
|--------|-------------|
| `post_impressions` | Times post was seen |
| `post_impressions_unique` | Unique users who saw post |
| `post_engaged_users` | Users who clicked/reacted |
| `post_clicks` | Link/photo/video clicks |
| `post_reactions_by_type_total` | Likes, loves, etc. breakdown |

### Get Post Performance

```typescript
interface PostPerformance {
  postId: string;
  impressions: number;
  reach: number;
  engagements: number;
  clicks: number;
  reactions: {
    like: number;
    love: number;
    wow: number;
    haha: number;
    sad: number;
    angry: number;
  };
}

async function getPostPerformance(
  postId: string,
  accessToken: string
): Promise<PostPerformance> {
  const metrics = [
    'post_impressions',
    'post_impressions_unique',
    'post_engaged_users',
    'post_clicks',
    'post_reactions_by_type_total',
  ].join(',');

  const res = await fetch(
    `https://graph.facebook.com/v21.0/${postId}/insights?` +
    `metric=${metrics}&access_token=${accessToken}`
  );

  const { data } = await res.json();

  const reactions = data.find(
    m => m.name === 'post_reactions_by_type_total'
  )?.values[0]?.value || {};

  return {
    postId,
    impressions: data.find(m => m.name === 'post_impressions')?.values[0]?.value || 0,
    reach: data.find(m => m.name === 'post_impressions_unique')?.values[0]?.value || 0,
    engagements: data.find(m => m.name === 'post_engaged_users')?.values[0]?.value || 0,
    clicks: data.find(m => m.name === 'post_clicks')?.values[0]?.value || 0,
    reactions: {
      like: reactions.like || 0,
      love: reactions.love || 0,
      wow: reactions.wow || 0,
      haha: reactions.haha || 0,
      sad: reactions.sad || 0,
      angry: reactions.angry || 0,
    },
  };
}
```

## Instagram Insights

### Account Insights

```bash
GET /{IG_ACCOUNT_ID}/insights?metric=impressions,reach,profile_views&period=day&access_token={TOKEN}
```

### Available Account Metrics

| Metric | Description | Periods |
|--------|-------------|---------|
| `impressions` | Total content views | day, week, days_28 |
| `reach` | Unique accounts reached | day, week, days_28 |
| `profile_views` | Profile page views | day |
| `website_clicks` | Bio link clicks | day |
| `follower_count` | Total followers | day |

### Get Instagram Account Insights

```typescript
interface IGAccountInsights {
  impressions: number;
  reach: number;
  profileViews: number;
  websiteClicks: number;
  followerCount: number;
}

async function getIGAccountInsights(
  igAccountId: string,
  accessToken: string
): Promise<IGAccountInsights> {
  const metrics = [
    'impressions',
    'reach',
    'profile_views',
    'website_clicks',
    'follower_count',
  ].join(',');

  const res = await fetch(
    `https://graph.facebook.com/v21.0/${igAccountId}/insights?` +
    `metric=${metrics}&period=day&access_token=${accessToken}`
  );

  const { data } = await res.json();

  return {
    impressions: data.find(m => m.name === 'impressions')?.values[0]?.value || 0,
    reach: data.find(m => m.name === 'reach')?.values[0]?.value || 0,
    profileViews: data.find(m => m.name === 'profile_views')?.values[0]?.value || 0,
    websiteClicks: data.find(m => m.name === 'website_clicks')?.values[0]?.value || 0,
    followerCount: data.find(m => m.name === 'follower_count')?.values[0]?.value || 0,
  };
}
```

### Instagram Media Insights

```bash
GET /{MEDIA_ID}/insights?metric=impressions,reach,engagement,saved&access_token={TOKEN}
```

### Available Media Metrics

| Metric | Media Types | Description |
|--------|-------------|-------------|
| `impressions` | All | Times content was seen |
| `reach` | All | Unique accounts |
| `engagement` | All | Likes + comments + saves |
| `saved` | All | Users who saved |
| `video_views` | Video/Reel | 3+ second views |
| `plays` | Reel | Total plays |
| `shares` | Reel | Share count |

### Get Media Performance

```typescript
interface IGMediaPerformance {
  mediaId: string;
  impressions: number;
  reach: number;
  engagement: number;
  saved: number;
  likes: number;
  comments: number;
}

async function getIGMediaPerformance(
  mediaId: string,
  accessToken: string
): Promise<IGMediaPerformance> {
  // Get insights
  const insightsRes = await fetch(
    `https://graph.facebook.com/v21.0/${mediaId}/insights?` +
    `metric=impressions,reach,saved&access_token=${accessToken}`
  );
  const { data: insights } = await insightsRes.json();

  // Get engagement counts
  const mediaRes = await fetch(
    `https://graph.facebook.com/v21.0/${mediaId}?` +
    `fields=like_count,comments_count&access_token=${accessToken}`
  );
  const media = await mediaRes.json();

  return {
    mediaId,
    impressions: insights.find(m => m.name === 'impressions')?.values[0]?.value || 0,
    reach: insights.find(m => m.name === 'reach')?.values[0]?.value || 0,
    engagement: media.like_count + media.comments_count,
    saved: insights.find(m => m.name === 'saved')?.values[0]?.value || 0,
    likes: media.like_count || 0,
    comments: media.comments_count || 0,
  };
}
```

## Node.js Implementation

```typescript
import axios from 'axios';

interface MetaInsightsConfig {
  pageId?: string;
  igAccountId?: string;
  accessToken: string;
}

class MetaInsights {
  private config: MetaInsightsConfig;
  private baseUrl = 'https://graph.facebook.com/v21.0';

  constructor(config: MetaInsightsConfig) {
    this.config = config;
  }

  private async fetch(endpoint: string) {
    const res = await axios.get(`${this.baseUrl}${endpoint}`, {
      params: { access_token: this.config.accessToken },
    });
    return res.data;
  }

  // Facebook Page insights
  async getPageOverview(period: 'day' | 'week' | 'days_28' = 'day') {
    const metrics = 'page_impressions,page_engaged_users,page_fans,page_fan_adds';
    const data = await this.fetch(
      `/${this.config.pageId}/insights?metric=${metrics}&period=${period}`
    );

    return this.parseInsights(data.data);
  }

  // Facebook post insights
  async getPostInsights(postId: string) {
    const metrics = 'post_impressions,post_engaged_users,post_clicks,post_reactions_by_type_total';
    const data = await this.fetch(`/${postId}/insights?metric=${metrics}`);
    return this.parseInsights(data.data);
  }

  // Instagram account insights
  async getIGOverview(period: 'day' | 'week' | 'days_28' = 'day') {
    const metrics = 'impressions,reach,profile_views,follower_count';
    const data = await this.fetch(
      `/${this.config.igAccountId}/insights?metric=${metrics}&period=${period}`
    );
    return this.parseInsights(data.data);
  }

  // Instagram media insights
  async getIGMediaInsights(mediaId: string) {
    const [insights, media] = await Promise.all([
      this.fetch(`/${mediaId}/insights?metric=impressions,reach,saved`),
      this.fetch(`/${mediaId}?fields=like_count,comments_count,media_type`),
    ]);

    return {
      ...this.parseInsights(insights.data),
      likes: media.like_count,
      comments: media.comments_count,
      mediaType: media.media_type,
    };
  }

  // Get top posts
  async getTopPosts(limit = 10) {
    // Get recent posts
    const posts = await this.fetch(
      `/${this.config.pageId}/posts?fields=id,message,created_time&limit=50`
    );

    // Get insights for each
    const postsWithInsights = await Promise.all(
      posts.data.map(async (post: any) => {
        const insights = await this.getPostInsights(post.id);
        return { ...post, insights };
      })
    );

    // Sort by engagement
    return postsWithInsights
      .sort((a, b) => (b.insights.post_engaged_users || 0) - (a.insights.post_engaged_users || 0))
      .slice(0, limit);
  }

  // Best posting times analysis
  async getBestPostingTimes() {
    const posts = await this.fetch(
      `/${this.config.pageId}/posts?fields=id,created_time&limit=100`
    );

    const postsWithInsights = await Promise.all(
      posts.data.map(async (post: any) => {
        const insights = await this.getPostInsights(post.id);
        const hour = new Date(post.created_time).getHours();
        const day = new Date(post.created_time).getDay();
        return { hour, day, engagement: insights.post_engaged_users || 0 };
      })
    );

    // Aggregate by hour
    const hourlyEngagement: Record<number, { total: number; count: number }> = {};
    postsWithInsights.forEach(({ hour, engagement }) => {
      if (!hourlyEngagement[hour]) {
        hourlyEngagement[hour] = { total: 0, count: 0 };
      }
      hourlyEngagement[hour].total += engagement;
      hourlyEngagement[hour].count += 1;
    });

    // Calculate averages and sort
    return Object.entries(hourlyEngagement)
      .map(([hour, { total, count }]) => ({
        hour: parseInt(hour),
        avgEngagement: total / count,
      }))
      .sort((a, b) => b.avgEngagement - a.avgEngagement);
  }

  private parseInsights(data: any[]) {
    const result: Record<string, any> = {};
    data.forEach((metric) => {
      result[metric.name] = metric.values[0]?.value;
    });
    return result;
  }
}

// Usage
const insights = new MetaInsights({
  pageId: process.env.FB_PAGE_ID!,
  igAccountId: process.env.IG_ACCOUNT_ID!,
  accessToken: process.env.FB_PAGE_ACCESS_TOKEN!,
});

// Get page overview
const pageStats = await insights.getPageOverview('week');
console.log('Page impressions:', pageStats.page_impressions);
console.log('Engaged users:', pageStats.page_engaged_users);
console.log('Total fans:', pageStats.page_fans);

// Get Instagram overview
const igStats = await insights.getIGOverview('day');
console.log('IG reach:', igStats.reach);
console.log('Profile views:', igStats.profile_views);

// Find best posting times
const bestTimes = await insights.getBestPostingTimes();
console.log('Best posting hours:', bestTimes.slice(0, 3));
```

## Dashboard Data Structure

```typescript
interface SocialDashboard {
  facebook: {
    followers: number;
    followersChange: number;
    impressions: number;
    engagement: number;
    topPosts: Array<{
      id: string;
      message: string;
      impressions: number;
      engagement: number;
    }>;
  };
  instagram: {
    followers: number;
    followersChange: number;
    reach: number;
    profileViews: number;
    topMedia: Array<{
      id: string;
      type: string;
      impressions: number;
      likes: number;
    }>;
  };
  recommendations: {
    bestPostingTimes: string[];
    contentSuggestions: string[];
  };
}

async function buildDashboard(
  insights: MetaInsights
): Promise<SocialDashboard> {
  const [fbToday, fbYesterday, igToday, igYesterday, topPosts] = await Promise.all([
    insights.getPageOverview('day'),
    insights.getPageOverview('day'), // Would need date range
    insights.getIGOverview('day'),
    insights.getIGOverview('day'),
    insights.getTopPosts(5),
  ]);

  return {
    facebook: {
      followers: fbToday.page_fans,
      followersChange: fbToday.page_fan_adds,
      impressions: fbToday.page_impressions,
      engagement: fbToday.page_engaged_users,
      topPosts: topPosts.map(p => ({
        id: p.id,
        message: p.message?.slice(0, 50) || '',
        impressions: p.insights.post_impressions,
        engagement: p.insights.post_engaged_users,
      })),
    },
    instagram: {
      followers: igToday.follower_count,
      followersChange: igToday.follower_count - (igYesterday.follower_count || 0),
      reach: igToday.reach,
      profileViews: igToday.profile_views,
      topMedia: [],
    },
    recommendations: {
      bestPostingTimes: ['9:00 AM', '12:00 PM', '7:00 PM'],
      contentSuggestions: [
        'Post more product photos - they get 2x engagement',
        'Try posting on Saturday mornings',
      ],
    },
  };
}
```

## Kenya-Specific Insights

```typescript
// Best posting times for Kenya (EAT timezone)
const kenyaBestTimes = {
  weekday: ['7:00-9:00', '12:00-14:00', '19:00-21:00'],
  weekend: ['10:00-12:00', '16:00-18:00', '20:00-22:00'],
};

// Convert UTC insights to EAT
function toKenyaTime(utcDate: Date): Date {
  return new Date(utcDate.getTime() + 3 * 60 * 60 * 1000); // UTC+3
}
```

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| Insights API | 200 calls/hour/user |
| Batch requests | 50 requests per batch |

## Resources

- [Page Insights Reference](https://developers.facebook.com/docs/graph-api/reference/page/insights)
- [Instagram Insights API](https://developers.facebook.com/docs/instagram-platform/insights)
