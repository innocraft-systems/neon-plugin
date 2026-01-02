---
name: status-scheduler
description: This skill provides guidance for scheduling WhatsApp Status content. Use when the user asks about "status scheduler", "content calendar", "posting reminders", "best time to post", "status automation", "content planning", or needs help organizing when to post Status updates.
---

# WhatsApp Status Scheduler

Plan, schedule, and get reminded when to post Status updates. Since WhatsApp Status can't be automated via API, this system generates content and sends reminders.

## Architecture Overview

```
┌─────────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Content Generator  │ ──▶ │  Content Queue   │ ──▶ │  Reminder       │
│  (Nano Banana/Veo)  │     │  (Ready posts)   │     │  (Push/SMS/WA)  │
└─────────────────────┘     └──────────────────┘     └─────────────────┘
                                                              │
                                                              ▼
                                                     ┌─────────────────┐
                                                     │  Business Owner │
                                                     │  Posts Manually │
                                                     └─────────────────┘
```

## Best Posting Times (Kenya)

Based on WhatsApp usage patterns in Kenya:

| Day | Best Times (EAT) | Reason |
|-----|------------------|--------|
| Weekday | 7:00-8:30 | Morning commute |
| Weekday | 12:00-13:30 | Lunch break |
| Weekday | 18:00-20:00 | Evening relaxation |
| Saturday | 10:00-12:00 | Weekend shopping |
| Saturday | 16:00-18:00 | Pre-dinner |
| Sunday | 11:00-13:00 | Post-church |
| Sunday | 19:00-21:00 | Week preparation |

## Database Schema

```typescript
// Content item ready for posting
interface ScheduledContent {
  id: string;
  tenantId: string;
  type: 'image' | 'video';
  filePath: string;
  caption?: string;
  scheduledFor: Date;
  status: 'pending' | 'reminded' | 'posted' | 'skipped';
  createdAt: Date;
  remindersSent: number;
}

// Content calendar
interface ContentCalendar {
  tenantId: string;
  weekStarting: Date;
  slots: Array<{
    dayOfWeek: number; // 0-6
    time: string; // "09:00"
    contentType: 'product' | 'promo' | 'testimonial' | 'general';
    contentId?: string;
  }>;
}

// Reminder preferences
interface ReminderSettings {
  tenantId: string;
  whatsappNumber: string;
  enableWhatsAppReminder: boolean;
  enablePushNotification: boolean;
  enableSMS: boolean;
  reminderMinutesBefore: number; // e.g., 15
  timezone: string; // "Africa/Nairobi"
}
```

## Scheduler Implementation

```typescript
import { CronJob } from 'cron';
import { Twilio } from 'twilio';

interface SchedulerConfig {
  db: Database;
  whatsappClient: WhatsAppClient;
  twilioClient?: Twilio;
  pushService?: PushService;
}

class StatusScheduler {
  private db: Database;
  private whatsapp: WhatsAppClient;
  private twilio?: Twilio;
  private push?: PushService;
  private jobs: Map<string, CronJob> = new Map();

  constructor(config: SchedulerConfig) {
    this.db = config.db;
    this.whatsapp = config.whatsappClient;
    this.twilio = config.twilioClient;
    this.push = config.pushService;
  }

  // Schedule content for a specific time
  async scheduleContent(
    tenantId: string,
    content: {
      type: 'image' | 'video';
      filePath: string;
      caption?: string;
    },
    scheduledFor: Date
  ): Promise<string> {
    const scheduled = await this.db.scheduledContent.create({
      data: {
        tenantId,
        type: content.type,
        filePath: content.filePath,
        caption: content.caption,
        scheduledFor,
        status: 'pending',
        remindersSent: 0,
      },
    });

    // Set up reminder job
    this.setupReminderJob(scheduled.id, scheduledFor, tenantId);

    return scheduled.id;
  }

  // Set up reminder cron job
  private setupReminderJob(
    contentId: string,
    scheduledFor: Date,
    tenantId: string
  ) {
    const settings = await this.db.reminderSettings.findUnique({
      where: { tenantId },
    });

    if (!settings) return;

    const reminderTime = new Date(
      scheduledFor.getTime() - settings.reminderMinutesBefore * 60 * 1000
    );

    const job = new CronJob(
      reminderTime,
      async () => {
        await this.sendReminder(contentId, tenantId);
      },
      null,
      true,
      settings.timezone
    );

    this.jobs.set(contentId, job);
  }

  // Send reminder via configured channels
  async sendReminder(contentId: string, tenantId: string) {
    const content = await this.db.scheduledContent.findUnique({
      where: { id: contentId },
    });

    if (!content || content.status !== 'pending') return;

    const settings = await this.db.reminderSettings.findUnique({
      where: { tenantId },
    });

    if (!settings) return;

    const message = `📱 Time to post your Status!\n\n` +
      `Content: ${content.type}\n` +
      `${content.caption ? `Caption: ${content.caption}\n` : ''}` +
      `\nOpen the app to post now.`;

    // WhatsApp reminder
    if (settings.enableWhatsAppReminder) {
      await this.whatsapp.sendTemplate(
        settings.whatsappNumber,
        'status_reminder',
        [content.type, content.caption || 'Ready to post']
      );
    }

    // SMS reminder
    if (settings.enableSMS && this.twilio) {
      await this.twilio.messages.create({
        body: message,
        to: settings.whatsappNumber,
        from: process.env.TWILIO_PHONE_NUMBER,
      });
    }

    // Push notification
    if (settings.enablePushNotification && this.push) {
      await this.push.send(tenantId, {
        title: 'Time to Post Status!',
        body: `Your ${content.type} is ready`,
        data: { contentId },
      });
    }

    // Update reminder count
    await this.db.scheduledContent.update({
      where: { id: contentId },
      data: { remindersSent: { increment: 1 } },
    });
  }

  // Mark content as posted
  async markAsPosted(contentId: string) {
    await this.db.scheduledContent.update({
      where: { id: contentId },
      data: { status: 'posted' },
    });

    // Cancel any remaining reminders
    const job = this.jobs.get(contentId);
    if (job) {
      job.stop();
      this.jobs.delete(contentId);
    }
  }

  // Get upcoming scheduled content
  async getUpcoming(tenantId: string, days: number = 7) {
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + days);

    return this.db.scheduledContent.findMany({
      where: {
        tenantId,
        scheduledFor: { lte: endDate },
        status: 'pending',
      },
      orderBy: { scheduledFor: 'asc' },
    });
  }

  // Auto-schedule content for the week
  async autoScheduleWeek(
    tenantId: string,
    contentItems: Array<{ type: 'image' | 'video'; filePath: string; caption?: string }>
  ) {
    const calendar = await this.db.contentCalendar.findUnique({
      where: { tenantId },
    });

    if (!calendar) {
      // Use default Kenya times
      return this.scheduleWithDefaults(tenantId, contentItems);
    }

    const scheduled = [];
    const now = new Date();

    for (let dayOffset = 0; dayOffset < 7; dayOffset++) {
      const date = new Date(now);
      date.setDate(date.getDate() + dayOffset);
      const dayOfWeek = date.getDay();

      const daySlots = calendar.slots.filter(s => s.dayOfWeek === dayOfWeek);

      for (const slot of daySlots) {
        const [hours, minutes] = slot.time.split(':').map(Number);
        const scheduledTime = new Date(date);
        scheduledTime.setHours(hours, minutes, 0, 0);

        if (scheduledTime > now && contentItems.length > 0) {
          const content = contentItems.shift()!;
          const id = await this.scheduleContent(tenantId, content, scheduledTime);
          scheduled.push({ id, time: scheduledTime, content });
        }
      }
    }

    return scheduled;
  }

  // Schedule with Kenya defaults
  private async scheduleWithDefaults(
    tenantId: string,
    contentItems: Array<{ type: 'image' | 'video'; filePath: string; caption?: string }>
  ) {
    const defaultTimes = {
      weekday: ['09:00', '13:00', '19:00'],
      weekend: ['11:00', '17:00', '20:00'],
    };

    const scheduled = [];
    const now = new Date();
    let contentIndex = 0;

    for (let dayOffset = 0; dayOffset < 7 && contentIndex < contentItems.length; dayOffset++) {
      const date = new Date(now);
      date.setDate(date.getDate() + dayOffset);
      const isWeekend = date.getDay() === 0 || date.getDay() === 6;
      const times = isWeekend ? defaultTimes.weekend : defaultTimes.weekday;

      for (const time of times) {
        if (contentIndex >= contentItems.length) break;

        const [hours, minutes] = time.split(':').map(Number);
        const scheduledTime = new Date(date);
        scheduledTime.setHours(hours, minutes, 0, 0);

        if (scheduledTime > now) {
          const content = contentItems[contentIndex++];
          const id = await this.scheduleContent(tenantId, content, scheduledTime);
          scheduled.push({ id, time: scheduledTime, content });
        }
      }
    }

    return scheduled;
  }
}
```

## Content Calendar API

```typescript
import express from 'express';

const router = express.Router();

// Get this week's calendar
router.get('/calendar', async (req, res) => {
  const { tenantId } = req.auth;

  const scheduled = await scheduler.getUpcoming(tenantId, 7);
  const calendar = formatAsCalendar(scheduled);

  res.json(calendar);
});

// Schedule single content
router.post('/schedule', async (req, res) => {
  const { tenantId } = req.auth;
  const { content, scheduledFor } = req.body;

  const id = await scheduler.scheduleContent(
    tenantId,
    content,
    new Date(scheduledFor)
  );

  res.json({ id, scheduledFor });
});

// Auto-schedule week
router.post('/auto-schedule', async (req, res) => {
  const { tenantId } = req.auth;
  const { contentItems } = req.body;

  const scheduled = await scheduler.autoScheduleWeek(tenantId, contentItems);

  res.json({ scheduled });
});

// Mark as posted
router.post('/content/:id/posted', async (req, res) => {
  const { id } = req.params;

  await scheduler.markAsPosted(id);

  res.json({ success: true });
});

// Update reminder settings
router.put('/settings/reminders', async (req, res) => {
  const { tenantId } = req.auth;
  const settings = req.body;

  await db.reminderSettings.upsert({
    where: { tenantId },
    create: { tenantId, ...settings },
    update: settings,
  });

  res.json({ success: true });
});

function formatAsCalendar(scheduled: ScheduledContent[]) {
  const calendar: Record<string, any[]> = {};

  scheduled.forEach(item => {
    const dateKey = item.scheduledFor.toISOString().split('T')[0];
    if (!calendar[dateKey]) {
      calendar[dateKey] = [];
    }
    calendar[dateKey].push({
      id: item.id,
      time: item.scheduledFor.toTimeString().slice(0, 5),
      type: item.type,
      caption: item.caption,
      status: item.status,
    });
  });

  return calendar;
}
```

## WhatsApp Reminder Template

Create this template in your WhatsApp Business account:

```json
{
  "name": "status_reminder",
  "language": "en",
  "category": "UTILITY",
  "components": [
    {
      "type": "BODY",
      "text": "📱 Status Reminder!\n\nYour {{1}} is ready to post.\n{{2}}\n\nOpen the app and post now for best engagement!",
      "example": {
        "body_text": [["product image", "Samsung A54 - KES 45,000"]]
      }
    },
    {
      "type": "BUTTONS",
      "buttons": [
        {
          "type": "QUICK_REPLY",
          "text": "Posted ✓"
        },
        {
          "type": "QUICK_REPLY",
          "text": "Skip"
        }
      ]
    }
  ]
}
```

## Content Pack Generator

```typescript
// Generate a week's worth of content
async function generateWeeklyContentPack(
  tenantId: string,
  products: Array<{ name: string; price: number; imageUrl: string }>
) {
  const imageGenerator = new StatusImageGenerator({
    apiKey: process.env.GOOGLE_API_KEY!,
    outputDir: `./content/${tenantId}`,
    usePro: true,
  });

  const contentItems = [];

  // Monday: New week, new products
  const mondayImage = await imageGenerator.productShowcase({
    name: products[0].name,
    price: products[0].price,
    features: [],
    description: 'Start the week right',
  });
  contentItems.push({
    type: 'image' as const,
    filePath: mondayImage,
    caption: 'Monday motivation! Check out our latest products 🔥',
  });

  // Wednesday: Mid-week promo
  const wednesdayImage = await imageGenerator.flashSale({
    discount: 15,
    endTime: 'Friday',
    category: 'Selected items',
  });
  contentItems.push({
    type: 'image' as const,
    filePath: wednesdayImage,
    caption: 'Mid-week deals! Limited time only ⏰',
  });

  // Friday: Weekend teaser
  const fridayImage = await imageGenerator.newArrival({
    name: 'Weekend Collection',
    tagline: 'Something special for the weekend',
  });
  contentItems.push({
    type: 'image' as const,
    filePath: fridayImage,
    caption: 'Weekend is here! What are you getting? 🛍️',
  });

  // Schedule all
  const scheduler = new StatusScheduler(config);
  const scheduled = await scheduler.autoScheduleWeek(tenantId, contentItems);

  return scheduled;
}
```

## Analytics Integration

```typescript
interface StatusPostAnalytics {
  contentId: string;
  postedAt: Date;
  views: number; // Self-reported
  inquiries: number; // WhatsApp messages after
  sales: number; // Attributed sales
}

// Track post performance (self-reported)
router.post('/content/:id/analytics', async (req, res) => {
  const { id } = req.params;
  const { views, inquiries, sales } = req.body;

  await db.statusAnalytics.create({
    data: {
      contentId: id,
      postedAt: new Date(),
      views,
      inquiries,
      sales,
    },
  });

  res.json({ success: true });
});

// Get best performing times
async function getBestPostingTimes(tenantId: string) {
  const analytics = await db.statusAnalytics.findMany({
    where: {
      content: { tenantId },
    },
    include: { content: true },
  });

  // Aggregate by hour
  const hourlyPerformance: Record<number, { total: number; count: number }> = {};

  analytics.forEach(a => {
    const hour = a.postedAt.getHours();
    if (!hourlyPerformance[hour]) {
      hourlyPerformance[hour] = { total: 0, count: 0 };
    }
    hourlyPerformance[hour].total += a.inquiries;
    hourlyPerformance[hour].count += 1;
  });

  return Object.entries(hourlyPerformance)
    .map(([hour, { total, count }]) => ({
      hour: parseInt(hour),
      avgInquiries: total / count,
    }))
    .sort((a, b) => b.avgInquiries - a.avgInquiries);
}
```

## Mobile App Integration

For the business owner's app:

```typescript
// React Native reminder handler
import PushNotification from 'react-native-push-notification';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Handle notification tap
PushNotification.configure({
  onNotification: async (notification) => {
    if (notification.data.type === 'status_reminder') {
      const contentId = notification.data.contentId;

      // Navigate to content preview
      navigation.navigate('StatusPreview', { contentId });
    }
  },
});

// Status posting screen
function StatusPreviewScreen({ route }) {
  const { contentId } = route.params;
  const [content, setContent] = useState(null);

  useEffect(() => {
    loadContent(contentId).then(setContent);
  }, [contentId]);

  const handlePosted = async () => {
    await api.post(`/content/${contentId}/posted`);
    Alert.alert('Great!', 'Content marked as posted');
    navigation.goBack();
  };

  const handleSkip = async () => {
    await api.post(`/content/${contentId}/skip`);
    navigation.goBack();
  };

  return (
    <View>
      {content?.type === 'image' ? (
        <Image source={{ uri: content.filePath }} style={styles.preview} />
      ) : (
        <Video source={{ uri: content.filePath }} style={styles.preview} />
      )}

      <Text style={styles.caption}>{content?.caption}</Text>

      <Text style={styles.instructions}>
        1. Long-press the image above to save{'\n'}
        2. Open WhatsApp{'\n'}
        3. Go to Status → Add Photo{'\n'}
        4. Select the saved image{'\n'}
        5. Post!
      </Text>

      <Button title="I've Posted It ✓" onPress={handlePosted} />
      <Button title="Skip This One" onPress={handleSkip} />
    </View>
  );
}
```

## Cron Jobs Setup

```typescript
import { CronJob } from 'cron';

// Check for upcoming reminders every minute
const reminderCheck = new CronJob(
  '* * * * *', // Every minute
  async () => {
    const upcoming = await db.scheduledContent.findMany({
      where: {
        status: 'pending',
        scheduledFor: {
          lte: new Date(Date.now() + 15 * 60 * 1000), // Next 15 mins
          gte: new Date(),
        },
        remindersSent: 0,
      },
      include: { tenant: true },
    });

    for (const content of upcoming) {
      await scheduler.sendReminder(content.id, content.tenantId);
    }
  },
  null,
  true,
  'Africa/Nairobi'
);

// Weekly content pack generation (Sunday evening)
const weeklyPack = new CronJob(
  '0 18 * * 0', // Sunday 6pm
  async () => {
    const tenants = await db.tenant.findMany({
      where: { autoGenerateContent: true },
    });

    for (const tenant of tenants) {
      const products = await db.product.findMany({
        where: { tenantId: tenant.id },
        take: 10,
        orderBy: { createdAt: 'desc' },
      });

      await generateWeeklyContentPack(tenant.id, products);
    }
  },
  null,
  true,
  'Africa/Nairobi'
);
```

## Best Practices

1. **Respect time zones** - Always use Africa/Nairobi for Kenya
2. **Don't over-remind** - Max 2 reminders per content
3. **Make posting easy** - One-tap save, clear instructions
4. **Track performance** - Learn best times for each business
5. **Batch generate** - Create week's content on Sunday
6. **Fallback gracefully** - If owner doesn't post, don't spam
