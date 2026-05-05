The structure already separates:

Primary engagement payouts (consume content → reward creators)
Derivative-content royalties (new creations built on prior creations)
Non-monetized moderation/social actions

What you’re really designing is a multi-hop attribution economy.

A few important architectural observations and improvements:

1. Your model has 3 earning layers
   A. Direct engagement earnings

Example:

User watches a video

Reward:

post author earns
optional sharer earns

This is straightforward CPM/CPE-style attribution.

B. Context-chain earnings

Example:

Someone reacts to a reply

You correctly route value upward:

reply author
comment author
post author

This is important because:

discussions become monetizable trees
creators benefit from hosting conversations
commenters are incentivized to write meaningful comments

This is similar to:

Reddit karma threading
YouTube comment ecosystems
Twitter/X reply engagement trees

But monetized.

C. Derivative-content royalties

This is the most innovative part.

Examples:

quote posts
stitches
reply posts
remixes

This introduces:

provenance
creative lineage
attribution royalties

That’s closer to:

Spotify sampling royalties
TikTok stitches
GitHub forks
academic citations

Very powerful if implemented well.

2. Important distinction: "engagement payout" vs "royalty payout"

These should NOT be treated the same internally.

You should separate:

Type	Meaning
Engagement payout	User interacted with content
Royalty payout	Another creator generated value from derivative work

Because royalties are recursive and long-lived.

Example:

Original Post A
↓ quote
Quote Post B
↓ stitch
Video C
↓ engagement
earnings generated

You now need lineage attribution.

3. Recommended attribution graph model

Instead of flat relationships, model content as a graph.

Example:

posts
-----
id
author_id
parent_post_id
root_post_id
relationship_type

relationship_type:

original
quote
stitch
reply_post
remix
duet

This enables:

ancestry traversal
royalty propagation
fraud detection
engagement lineage analytics
4. Royalty propagation strategy

Do NOT infinitely recurse royalties upward.

That becomes:

expensive
gameable
impossible to explain

Instead use:

Level	Suggested payout
Direct creator	100% base
Immediate parent	10–20% royalty
Root/original creator	optional 2–5%
Beyond that	stop

Example:

Reply Post earns $1.00

Reply author:
$0.85

Original post author:
$0.15

Or:

Stitch earns $10

Stitch creator:
$8.50

Original creator:
$1.50

Simple.
Understandable.
Auditable.

5. Sharer payouts need anti-spam rules

This area becomes heavily abused if not constrained.

Without limits:

fake engagement rings
self-sharing loops
bot amplification

Recommended conditions:

Sharer only earns if:

viewer is unique
viewer is not the sharer
viewer watched meaningful duration
engagement occurred within attribution window
share was actual acquisition source

Example:

share_attribution_window = 7 days
minimum_watch_seconds = 5
6. You should classify events into weighted-value tiers

Not all engagement has equal value.

Recommended normalized scoring model:

Event	Weight
Impression	1
View > 5 sec	3
Full watch	8
Reaction	5
Comment	12
Reply	15
Share	20
Follow from post	30
Subscribe from post	100

Then platform revenue allocation becomes:

creator_share =
(event_weight / total_weight_pool)
× revenue_pool

This scales much better than hardcoded per-event payouts.

7. Comments/replies should probably decay upward

Right now:

reply on reply → post author + comment author + reply author

Good idea, but you should avoid over-fragmentation.

Better:

Actor	Share
immediate parent	highest
host post author	medium
upper ancestors	tiny or none

Otherwise:

accounting explodes
payouts become microscopic
users cannot understand earnings
8. Introduce “engagement quality” scoring

Otherwise low-quality ragebait dominates.

Possible multipliers:

Signal	Effect
meaningful watch time	boost
repeat viewers	boost
follow conversion	boost
hides/reports	penalty
rapid bounce	penalty
spam likelihood	penalty

This becomes your creator-quality ranking layer.

9. Your system is essentially an "engagement ledger"

You’re implicitly building:

event
→ attribution engine
→ journal lines
→ payout ledger
→ creator wallet

Very fintech-like.

You even used the correct term:

journal_lines

That’s exactly how this should work.

Recommended ledger structure:

engagement_events
attribution_results
journal_entries
wallet_balances
payout_batches
10. Most important future problem: Sybil attacks

The hardest issue will not be payouts.

It will be:

fake accounts
engagement farms
self-interaction loops
coordinated rings

You will eventually need:

Defense	Purpose
trust scores	identify quality users
device fingerprinting	detect farms
payout delays	fraud review
rolling reserves	clawbacks
behavioral ML	bot detection
diminishing returns	prevent spam loops

Every monetized social platform faces this.

11. Strong conceptual naming improvement

Instead of:

Secondary earners

Consider:

Current	Better
Secondary earners	Attribution beneficiaries
Share initiation credit	Distribution credit
Inspiration royalty	Derivative royalty
Host share	Context royalty

These sound more platform-grade.

12. This system becomes extremely powerful with creator analytics

Imagine dashboards like:

Revenue Sources
---------------
42% direct engagement
28% shares
18% derivative royalties
12% follower conversions

Or:

Top downstream creators inspired by you

That’s where creator retention becomes huge.

Final assessment

This is not just:

“pay creators for likes”

It’s evolving toward:

a provenance-aware creator economy ledger

The strongest part is:

derivative attribution
threaded conversation monetization
share/distribution credit

That’s where your platform becomes differentiated from normal social media.



...............................................


A good creator revenue report should answer 5 questions instantly:

How much did I earn?
Where did it come from?
Which content generated it?
Who amplified it?
What should I do next?

If your platform supports:

engagement payouts
attribution chains
derivative royalties
sharer economics
conversation monetization

…then your revenue report becomes much richer than YouTube/TikTok dashboards.

A detailed report could look like this:

Creator Revenue Report
Creator Revenue Report
Period: April 1 – April 30, 2026
Creator: @andrew
Creator ID: cr_849201
Currency: USD
1. Revenue Summary
   TOTAL EARNINGS
--------------------------------
Gross Revenue              $4,283.12
Platform Fee               -$428.31
Fraud / Risk Reserve       -$91.22
Net Creator Earnings       $3,763.59
Pending Clearance          $214.11
Paid Out                   $3,549.48
2. Revenue Breakdown by Source

This becomes one of the most important sections.

REVENUE SOURCES
-------------------------------------------------
Direct Post Engagement           $1,842.21
Video Watch-Time                 $932.11
Comment Tree Earnings            $418.09
Share Distribution Credits       $291.42
Derivative Royalties             $403.18
Follower Conversion Rewards      $109.87
Subscription Discovery Rewards   $286.24
-------------------------------------------------
TOTAL                             $4,283.12

This tells creators:

whether they are good at creating
distributing
sparking discussion
inspiring derivatives
converting audiences
3. Earnings by Content
   TOP EARNING POSTS
------------------------------------------------------------------------------------------------
Post ID     Type      Views     Engagements    Shares    Revenue
------------------------------------------------------------------------------------------------
pst_9912    Video     428K      31.2K          8.1K      $1,142.88
pst_7741    Thread     88K       9.8K          2.3K      $492.22
pst_9919    Meme      212K      18.1K          6.0K      $441.18
pst_7754    ReplyPost  41K       6.2K          1.4K      $308.10
------------------------------------------------------------------------------------------------
4. Engagement Event Revenue

This section explains how money was generated.

ENGAGEMENT EVENT EARNINGS
-----------------------------------------------------------------------
Event Type                  Count            Revenue
-----------------------------------------------------------------------
Impressions                 2,441,119        $244.11
Video Watch Seconds         18,221,441       $932.11
Reactions                   188,112          $518.32
Comments                    22,118           $411.18
Replies                     11,901           $287.00
Shares                      31,992           $291.42
Bookmarks                   8,201            $88.09
Follow Conversions          2,118            $109.87
Subscription Conversions      418            $286.24
-----------------------------------------------------------------------
5. Derivative Royalty Earnings

This is where your platform becomes unique.

DERIVATIVE CONTENT ROYALTIES
---------------------------------------------------------------------------------------------------
Derivative Type     Derived Posts     Total Derivative Views     Royalty Earned
---------------------------------------------------------------------------------------------------
Quote Posts         1,882             4.2M                       $188.12
Reply Posts           918             1.9M                       $111.42
Stitches               77             2.8M                       $92.19
Remixes                21             0.4M                       $11.45
---------------------------------------------------------------------------------------------------
TOTAL                                                                  $403.18

Now creators can see:

“People building on my content makes me money.”

That’s a massive behavioral incentive.

6. Top Downstream Creators

Very powerful psychologically.

TOP CREATORS WHO GENERATED YOU ROYALTIES
------------------------------------------------------------------------------------
Creator          Derived Posts      Views Generated      Your Royalty Earnings
------------------------------------------------------------------------------------
@maya            118                1.2M                 $92.11
@techalex         42                0.8M                 $61.22
@dailyclips       71                0.6M                 $54.88
------------------------------------------------------------------------------------

This encourages:

collaborations
creator ecosystems
creator alliances
7. Share Attribution Report

You already support sharer earnings.

Now expose it.

DISTRIBUTION ATTRIBUTION
--------------------------------------------------------------------------------
Traffic Source                  Views         Revenue Generated
--------------------------------------------------------------------------------
Direct Feed                     1.1M          $1,022.88
External Shares                 0.8M          $711.22
Internal Reposts                0.5M          $433.11
DM Shares                       0.2M          $188.41
Community Threads               0.1M          $92.22
--------------------------------------------------------------------------------
8. Conversation Revenue Tree

This is extremely differentiated.

COMMENT TREE EARNINGS
-----------------------------------------------------------------------
Source                          Revenue
-----------------------------------------------------------------------
Direct comments                 $211.11
Replies on comments             $119.42
Replies on replies              $48.18
Reactions on comments           $22.81
Reactions on replies            $16.57
-----------------------------------------------------------------------

This teaches creators:

discussions are assets

9. Audience Conversion Funnel

Helps creators optimize.

AUDIENCE CONVERSION FUNNEL
---------------------------------------------------------
Impressions                     2.4M
Views                           1.1M
Engaged Users                   221K
Followers Gained                2,118
Subscribers Gained                418
Subscriber Conversion Rate      0.037%
---------------------------------------------------------
10. Risk / Integrity Adjustments

Very important for trust.

INTEGRITY & QUALITY ADJUSTMENTS
-------------------------------------------------------------------
Invalid Traffic Removed             118,221 events
Bot Engagement Reversed             $28.18
Fraud Hold Reserve                  $91.22
Spam Engagement Penalty             -$14.88
Net Adjustment                      -$134.28
-------------------------------------------------------------------

Without this:

creators accuse platform of theft
fraud disputes explode
11. Geographic Revenue Sources
    TOP AUDIENCE COUNTRIES
-----------------------------------------------------
Country              Revenue       CPM Equivalent
-----------------------------------------------------
United States        $1,281.11     $4.88
Canada               $611.22       $3.92
United Kingdom       $488.01       $4.11
Nigeria              $311.98       $1.08
India                $201.88       $0.82
-----------------------------------------------------
12. Revenue Timeline
    DAILY EARNINGS
------------------------------------------------
Apr 01    $88.11
Apr 02    $91.22
Apr 03    $201.88
Apr 04    $611.92  ← Viral stitch spike
Apr 05    $441.02
...
------------------------------------------------

You can annotate:

viral spikes
derivative explosions
share cascades
13. Wallet & Payouts
    WALLET STATUS
------------------------------------------------
Available Balance         $1,411.92
Pending Clearance         $214.11
Next Payout Date          May 7, 2026
Lifetime Earnings         $28,118.41
------------------------------------------------
14. Suggested Insights (AI layer)

This becomes extremely valuable.

CREATOR INSIGHTS
---------------------------------------------------------
• Posts with debate-heavy comments earned 2.1× more
• Quote-postable content generated 18% of revenue
• Videos under 42 seconds performed best
• External shares from Discord converted highest
• Your followers react most between 7–10 PM
---------------------------------------------------------

This turns analytics into strategy.

15. Raw Ledger Export (advanced creators)

Power users will want:

CSV Export:
event_id
timestamp
event_type
source_post
viewer_id_hash
revenue_generated
royalty_split
final_creator_share

Especially important for:

audits
agencies
taxes
creator studios
Architectural insight

Your platform is effectively combining:

System	Inspiration
Social graph	Twitter/X
Engagement monetization	TikTok/YouTube
Attribution economy	Spotify sampling
Thread monetization	Reddit
Revenue ledger	Stripe
Creator analytics	YouTube Studio

That combination is rare.

The derivative royalty + threaded conversation earnings are the most differentiated pieces.