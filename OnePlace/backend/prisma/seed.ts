import { config } from 'dotenv'
config({ path: '.env' })
config({ path: '.env.development.local', override: true })

import bcrypt from 'bcryptjs'
import { PrismaClient } from '@prisma/client'
import { PrismaPg } from '@prisma/adapter-pg'
import { Pool } from 'pg'

const pool = new Pool({ connectionString: process.env.DATABASE_URL! })
const adapter = new PrismaPg(pool)
const prisma = new PrismaClient({ adapter })

// ─── Seed Data ────────────────────────────────────────────────────────────────

const SEED_USERS = [
  { firstname: 'Alex',   lastname: 'Carter',   email: 'alex.carter@oneplace.dev'    },
  { firstname: 'Maya',   lastname: 'Torres',   email: 'maya.torres@oneplace.dev'    },
  { firstname: 'Jordan', lastname: 'Lee',      email: 'jordan.lee@oneplace.dev'     },
  { firstname: 'Priya',  lastname: 'Patel',    email: 'priya.patel@oneplace.dev'    },
  { firstname: 'Noah',   lastname: 'Williams', email: 'noah.williams@oneplace.dev'  },
  { firstname: 'Sofia',  lastname: 'Chen',     email: 'sofia.chen@oneplace.dev'     },
  { firstname: 'Ethan',  lastname: 'Brown',    email: 'ethan.brown@oneplace.dev'    },
  { firstname: 'Lila',   lastname: 'Nguyen',   email: 'lila.nguyen@oneplace.dev'    },
  { firstname: 'Marcus', lastname: 'Johnson',  email: 'marcus.johnson@oneplace.dev' },
  { firstname: 'Zoe',    lastname: 'Kim',      email: 'zoe.kim@oneplace.dev'        },
]

const NOW = new Date()
const daysAgo = (n: number) => new Date(NOW.getTime() - n * 86_400_000)
const hoursAfter = (base: Date, h: number) => new Date(base.getTime() + h * 3_600_000)

// ─── Posts ────────────────────────────────────────────────────────────────────

const POST_DEFS = [
  {
    u: 0, days: 13,
    title: 'Excited to finally be here! 👋',
    content: "Hey everyone! I just joined this community and I'm already blown away by the quality of content and the vibe here. A little about me: I'm a self-taught developer working on building better habits around learning. Super excited to connect with all of you and grow together. Drop a hi below!",
  },
  {
    u: 1, days: 12,
    title: 'What brought you to this community?',
    content: "I'm curious — what was the thing that made you join? For me, I was looking for a place where learning is taken seriously but the community still feels warm and supportive. Would love to hear your stories!",
  },
  {
    u: 2, days: 12,
    title: 'My learning goals for this month',
    content: "Trying something new this month: writing my goals publicly for accountability. Here's my list:\n\n1. Complete 2 courses on the platform\n2. Write at least 3 posts sharing what I've learned\n3. Engage with at least 10 community members\n4. Apply one new concept to a real project\n\nAnyone else want to share their goals?",
  },
  {
    u: 3, days: 11,
    title: 'How do you stay consistent with learning?',
    content: "Consistency is the hardest part for me. I'll go strong for a week and then life happens and I fall off for a few days. By the time I come back, I've lost momentum. What systems or habits have worked for you to keep showing up every day, even when it's hard?",
  },
  {
    u: 4, days: 11,
    title: 'Productivity tips that actually changed my workflow',
    content: "After years of trying different systems, here's what stuck:\n\n• Time-blocking over to-do lists: assign tasks to specific time slots\n• The 2-minute rule: if it takes less than 2 minutes, do it now\n• Weekly reviews every Sunday\n• Phone out of the room during deep work\n\nWhat works for you? I'd love to add more to this list.",
  },
  {
    u: 5, days: 10,
    title: 'Weekly wins — share yours! 🏆',
    content: "Let's celebrate each other's progress, no matter how small! Post your wins from this week below. Finished a chapter? Built something? Had a breakthrough? All of it counts. I'll go first: I finally understood a concept I've been stuck on for 3 weeks. Feels amazing!",
  },
  {
    u: 6, days: 10,
    title: 'Resources I wish I had when I started',
    content: "For anyone newer here, these are the things that helped me the most:\n\n• The courses here (obviously!)\n• Writing summaries of what I learn — teaching solidifies it\n• Following focused creators instead of passive browsing\n• Having a dedicated learning space at home\n\nWhat would you add?",
  },
  {
    u: 7, days: 9,
    title: 'Struggling with motivation lately — honest post',
    content: "Being real: the last two weeks have been rough. I've been showing up but not really present — just going through the motions. I know the remedy is usually to reconnect with your why, but sometimes even that feels forced. Has anyone been through this? How did you push through?",
  },
  {
    u: 8, days: 9,
    title: 'Just hit a major milestone 🎉',
    content: "Wanted to share this with the community because you've all been part of this journey. I just completed something I've been working toward for 3 months. It wasn't easy, there were plenty of setbacks, but staying the course finally paid off. Thank you all for the encouragement. Onwards!",
  },
  {
    u: 9, days: 8,
    title: "Quick intro — let's connect! 🌍",
    content: "Hey! I'm Zoe, joining from the Pacific Northwest. I work in design by day and I'm passionate about learning skills at the intersection of creativity and technology. Would love to connect with people who are building things, learning things, and generally trying to level up. Say hi!",
  },
  {
    u: 0, days: 7,
    title: 'How I structure my daily learning blocks',
    content: "After a lot of trial and error, I settled on this:\n\n• 6:30–7:00 AM: Review yesterday's notes\n• 12:00–12:30 PM: Lunch break = one lesson or article\n• 9:00–10:00 PM: Main deep-work learning block\n\nThe key insight: consistency beats duration. 30 minutes every day beats 4 hours once a week.",
  },
  {
    u: 1, days: 7,
    title: 'Best podcasts for personal growth? Drop your recs 🎧',
    content: "Building out my podcast list for commutes and workouts. Looking for shows about learning, productivity, building skills, or becoming a better version of yourself. What are you currently listening to? I'll compile the best suggestions into a post for everyone.",
  },
  {
    u: 2, days: 6,
    title: 'Looking for an accountability partner 🤝',
    content: "Anyone interested in pairing up for accountability? The idea: we check in weekly, share goals and blockers, and help each other stay on track. I've done this before and it's a game-changer. DM me or comment if you're interested — open to anyone regardless of what you're working on.",
  },
  {
    u: 3, days: 5,
    title: "The most valuable lesson I've learned here",
    content: "Six weeks in and the biggest takeaway isn't a skill or technique — it's this: the learning compounds. The things you learn in week 1 become context for week 6. You don't always see the value in the moment. Trust the process, show up consistently, and let the compounding do its thing.",
  },
  {
    u: 4, days: 5,
    title: 'Tools I use every single day',
    content: "People always ask about my setup, so here it is:\n\n• Notion for notes and project management\n• Readwise for reviewing book and article highlights\n• A paper notebook for thinking (not recording)\n• Forest app for focus sessions\n\nWhat's in your stack?",
  },
  {
    u: 5, days: 4,
    title: "Friday motivation 💪 — let's finish strong!",
    content: "Friday isn't the finish line, it's a checkpoint. Use today to reflect: what did you learn, what would you do differently, what are you proud of? Then rest and recharge intentionally this weekend. See you all on the other side, stronger and sharper.",
  },
  {
    u: 6, days: 3,
    title: "Honest reflection: where I am vs where I thought I'd be",
    content: "Three months ago I set some ambitious goals. Time to be honest with myself. Some things are ahead of schedule, others are behind. The interesting part: the things that fell behind weren't due to lack of effort — they required rethinking my approach entirely. Real growth rarely looks like a straight line.",
  },
  {
    u: 7, days: 3,
    title: 'How do you handle burnout?',
    content: "I think I'm hitting a wall. Not a giving-up wall, more of a need-to-recover wall. Do you push through, take a complete break, or shift to lighter activities? I want to recover properly, not just take time off and come back in the same hole.",
  },
  {
    u: 8, days: 2,
    title: "30-day community challenge 🔥 — who's in?",
    content: "Here's the challenge: for 30 days, do at least ONE thing that moves you closer to your goal. Doesn't have to be huge. Read one page. Write one paragraph. Watch one lesson. Post one update. Just don't break the chain. I'll be posting daily check-ins. Who's joining me?",
  },
  {
    u: 9, days: 1,
    title: 'This community is something special ❤️',
    content: "I've been part of a few online communities before and this one genuinely stands out. The quality of discussion, the support, the willingness to be honest — it's rare. I just wanted to say thank you to everyone here. You make showing up worthwhile. Here's to what we'll all build together.",
  },
]

// ─── Comments ─────────────────────────────────────────────────────────────────
// [postIndex, userIndex, content, hoursAfterPost]

type CommentDef = [number, number, string, number]

const COMMENT_DEFS: CommentDef[] = [
  // Post 0 — Alex joins
  [0, 1, "Welcome Alex! You're going to love it here. The community is genuinely one of the best parts.", 2],
  [0, 4, "Welcome! Jump into the courses whenever you're ready — they're worth it.", 5],
  [0, 8, "Welcome aboard! Excited to have another developer in the mix 🙌", 9],

  // Post 1 — Maya asks what brought people
  [1, 0, "Honestly? I was tired of learning in isolation. Wanted accountability and real conversations, not just tutorials.", 3],
  [1, 6, "I found this place through a recommendation and stayed for the quality of discussion. Never looked back.", 7],
  [1, 9, "Same as Ethan — quality drew me in, community made me stay.", 10],
  [1, 3, "I needed structure and a sense of direction. This community gave me both.", 14],

  // Post 2 — Jordan's goals
  [2, 5, "Love this! Public accountability is powerful. Adding you to my mental check-in list 😄", 2],
  [2, 7, "Goal #3 is underrated. Commenting and engaging actually reinforces your own learning.", 5],
  [2, 0, "This inspired me to write down my own goals. Sharing is caring — thanks Jordan!", 8],

  // Post 3 — Priya on consistency
  [3, 2, "What helped me: habit stacking. Pair learning with something you already do daily. Coffee + one lesson = easy.", 2],
  [3, 9, "I stopped relying on motivation and started relying on environment. Made it harder NOT to learn. Game changer.", 6],
  [3, 4, "Be okay with streaks breaking. The comeback from a missed day matters more than the streak itself.", 10],

  // Post 4 — Noah's productivity tips
  [4, 1, "The time-blocking tip is gold. Changed my whole relationship with my calendar.", 1],
  [4, 3, "Phone out of the room... I know this works and I still don't do it enough. Adding it back today.", 4],
  [4, 6, "Weekly reviews are so underrated. I do mine on Friday afternoon — best 30 minutes of my week.", 8],
  [4, 8, "The 2-minute rule is still one of the best productivity ideas I've ever encountered.", 11],

  // Post 5 — Sofia's weekly wins
  [5, 0, "Win: I finally shipped a side project I've been sitting on for weeks. Small but real.", 2],
  [5, 2, "Win: I read for 20 minutes every night this week. Not huge but consistent!", 5],
  [5, 7, "Win: I asked for help instead of struggling alone for 3 hours. Turns out asking is a skill too.", 9],
  [5, 9, "Win: I introduced myself to 3 new people in the community. Connections matter!", 12],

  // Post 6 — Ethan's resources
  [6, 1, "Writing summaries is so underrated. Explaining it forces you to find gaps in your own understanding.", 3],
  [6, 4, "The dedicated environment tip is huge. I have a specific chair I only use for learning. Signal is everything.", 7],
  [6, 7, "I'd add: find at least one person 3–5 years ahead of where you want to be and study how they think.", 11],

  // Post 7 — Lila struggling
  [7, 0, "I've been there more times than I can count. Sometimes 2 days completely off is more productive than forcing it.", 2],
  [7, 3, "Lower the bar. Tell yourself you only need to show up for 5 minutes. Usually you end up doing more.", 5],
  [7, 5, "Going through the motions is often just before a breakthrough. Keep showing up even if it feels empty.", 9],
  [7, 8, "Honest check: is it burnout or boredom? Switching topics temporarily can reset everything.", 13],

  // Post 8 — Marcus milestone
  [8, 1, "CONGRATS! 🎉 Three months of consistent effort — that's the real achievement. What's next?", 1],
  [8, 5, "This made my day. Proof that staying the course pays off. Well done!", 4],
  [8, 9, "Amazing! Would love to hear what you were working on if you're open to sharing!", 7],

  // Post 9 — Zoe intro
  [9, 0, "Welcome Zoe! Design + tech is such a powerful combo. You're going to fit right in here.", 2],
  [9, 4, "Hey! Fellow creative-technical person here. Great to have you!", 6],
  [9, 6, "Welcome! Looking forward to seeing what you create and share.", 10],

  // Post 10 — Alex learning blocks
  [10, 2, "The evening block is the move. Brain is tired but reviewing before sleep is great for retention.", 3],
  [10, 7, "Consistency beats duration — printing this and putting it on my monitor right now.", 6],
  [10, 5, "The morning review habit is smart. I'm going to try this. Thanks for sharing the system!", 10],

  // Post 11 — Maya podcast recs
  [11, 3, "Huberman Lab for anything related to focus, sleep, and performance. Non-negotiable for me.", 2],
  [11, 6, "The Knowledge Project with Shane Parrish. Deeply thoughtful conversations about decision-making.", 6],
  [11, 8, "+1 for anything by Tim Ferriss. Long form but always worth it.", 10],

  // Post 12 — Jordan accountability partner
  [12, 1, "I'm in! Just sent you a message. Let's build something good.", 2],
  [12, 9, "Great idea. I've been looking for something like this. Interested!", 5],
  [12, 5, "This is such a good idea. If you pair up and it works, let us know — might want to do it as a community thing.", 9],

  // Post 13 — Priya's lesson
  [13, 0, "The compounding metaphor is so accurate. Week 1 me had no idea what week 6 me would know.", 3],
  [13, 4, "Trust the process. This community embodies that. Well said, Priya.", 7],

  // Post 14 — Noah's tools
  [14, 1, "Notion is life. My second brain has a second brain.", 2],
  [14, 7, "The paper notebook for thinking is underrated. There's something different about analog.", 6],
  [14, 3, "Readwise is incredible. Changed how I retain what I read.", 9],

  // Post 15 — Sofia Friday motivation
  [15, 2, "This is exactly the energy I needed today. Thank you Sofia!", 1],
  [15, 8, "Fridays are when I do my week-in-review. This pairs perfectly with that habit.", 5],

  // Post 16 — Ethan honest reflection
  [16, 5, "Love the honesty here. Most people only post the highlight reel. This is refreshing.", 3],
  [16, 0, "The straight-line growth myth is the most damaging thing in learning culture. Real growth is messy.", 7],
  [16, 9, "This resonates deeply. Rethinking the approach is itself a form of progress.", 11],

  // Post 17 — Lila burnout
  [17, 4, "Lighter activities is the answer for me. I switch to reading (not studying) when I'm in that space.", 2],
  [17, 2, "Complete break, but scheduled. Set an end date so it doesn't become indefinite avoidance.", 6],
  [17, 6, "Rest is part of the process, not a break from it. Recovering intentionally is not falling behind.", 10],

  // Post 18 — Marcus 30-day challenge
  [18, 1, "IN! Starting today. One action, every day, no matter what.", 1],
  [18, 3, "Joining this. Finally building the daily writing habit I keep postponing.", 3],
  [18, 7, "Count me in 🔥 This is exactly the nudge I needed.", 6],
  [18, 9, "Challenge accepted. See you all in 30 days 💪", 9],

  // Post 19 — Zoe thank you
  [19, 0, "Agreed 100%. There's something different here and I think it's the intention people bring.", 2],
  [19, 5, "This community is what everyone in it makes it. So thank you too, Zoe!", 5],
  [19, 8, "I felt the same way within my first week. Glad you're here.", 8],
]

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  // Find "Test Community"
  const community = await prisma.community.findFirst({
    where: { name: 'Test Community' },
  })
  if (!community) {
    throw new Error('"Test Community" not found. Please create it in the app first.')
  }
  console.log(`✓ Found community: "${community.name}" (${community.id})`)

  // Guard: skip if already seeded
  const alreadySeeded = await prisma.user.count({
    where: { email: { in: SEED_USERS.map(u => u.email) } },
  })
  if (alreadySeeded === SEED_USERS.length) {
    console.log('✓ Seed users already exist — skipping to avoid duplicates.')
    console.log('\n  Login with any seed user (password: Testing123!):')
    SEED_USERS.forEach(u => console.log(`  ${u.email}`))
    return
  }

  // 1. Create users
  const passwordHash = await bcrypt.hash('Testing123!', 10)

  const users = await Promise.all(
    SEED_USERS.map(u =>
      prisma.user.upsert({
        where: { email: u.email },
        update: {},
        create: {
          firstname: u.firstname,
          lastname: u.lastname,
          email: u.email,
          password: passwordHash,
          isVerified: true,
        },
      })
    )
  )
  console.log(`✓ Created ${users.length} users`)

  // 2. Create memberships + subscriptions
  // SUBSCRIPTION communities require a successful Subscription record or the
  // hourly expiry job will immediately expire the membership on next run.
  const oneYearFromNow = new Date(NOW.getTime() + 365 * 24 * 60 * 60 * 1000)

  await Promise.all(
    users.map(async u => {
      const membership = await prisma.membership.upsert({
        where: { userId_communityId: { userId: u.id, communityId: community.id } },
        update: {},
        create: {
          userId: u.id,
          communityId: community.id,
          role: 'member',
          status: 'ACTIVE',
          pricingModelAtJoin: community.pricingModel,
          membershipTier: 'FREE',
          joinedAt: daysAgo(14),
        },
      })
      if (community.pricingModel === 'SUBSCRIPTION') {
        const hasSub = await prisma.subscription.count({
          where: { membershipId: membership.id, paymentStatus: 'SUCCESS' },
        })
        if (hasSub === 0) {
          await prisma.subscription.create({
            data: {
              membershipId: membership.id,
              billingInterval: 'MONTHLY',
              subscriptionStart: daysAgo(14),
              subscriptionEnd: oneYearFromNow,
              pricePaid: 0,
              paymentStatus: 'SUCCESS',
            },
          })
        }
      }
    })
  )
  console.log(`✓ Created memberships`)

  // Award join points
  await prisma.userPoints.createMany({
    data: users.map(u => ({
      userId: u.id,
      communityId: community.id,
      action: 'MEMBERSHIP_JOINED' as const,
      points: 5,
      createdAt: daysAgo(14),
    })),
  })

  // 3. Create posts
  const posts = await Promise.all(
    POST_DEFS.map(def => {
      const ts = daysAgo(def.days)
      return prisma.post.create({
        data: {
          communityId: community.id,
          authorId: users[def.u].id,
          title: def.title,
          content: def.content,
          type: 'TEXT',
          createdAt: ts,
          updatedAt: ts,
        },
      })
    })
  )
  console.log(`✓ Created ${posts.length} posts`)

  // Award post points
  await prisma.userPoints.createMany({
    data: POST_DEFS.map(def => ({
      userId: users[def.u].id,
      communityId: community.id,
      action: 'POST_CREATED' as const,
      points: 5,
      createdAt: daysAgo(def.days),
    })),
  })

  // 4. Create comments
  const comments = await Promise.all(
    COMMENT_DEFS.map(([pIdx, uIdx, content, h]) => {
      const ts = hoursAfter(daysAgo(POST_DEFS[pIdx].days), h)
      return prisma.comment.create({
        data: {
          postId: posts[pIdx].id,
          authorId: users[uIdx].id,
          content,
          createdAt: ts,
          updatedAt: ts,
        },
      })
    })
  )
  console.log(`✓ Created ${comments.length} comments`)

  // Award comment points
  await prisma.userPoints.createMany({
    data: COMMENT_DEFS.map(([pIdx, uIdx, , h]) => ({
      userId: users[uIdx].id,
      communityId: community.id,
      action: 'COMMENT_CREATED' as const,
      points: 2,
      createdAt: hoursAfter(daysAgo(POST_DEFS[pIdx].days), h),
    })),
  })

  console.log('\n✅ Seed complete!')
  console.log(`   Community : ${community.name}`)
  console.log(`   Users     : ${users.length}`)
  console.log(`   Posts     : ${posts.length}`)
  console.log(`   Comments  : ${comments.length}`)
  console.log('\n   Login credentials (all users share this password):')
  console.log('   Password  : Testing123!')
  console.log('')
  SEED_USERS.forEach(u => console.log(`   ${u.email}`))
}

main()
  .catch(err => { console.error('\n❌ Seed failed:', err); process.exit(1) })
  .finally(() => prisma.$disconnect().then(() => pool.end()))
