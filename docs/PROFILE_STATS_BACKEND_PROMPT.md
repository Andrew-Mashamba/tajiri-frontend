# Profile stats – backend information request

**Purpose:** We want to enrich the profile screen stats section. To do that we need a clear list of all user-related counts/metrics your API already exposes or can expose.

---

## Copy-paste prompt (send this to backend / product)

**Subject:** User profile – list of available (or possible) user stats/counts for the app

Hi,

We’re improving the profile screen and want to show more stats (e.g. Posts, Friends, Photos, Videos, etc.) in the stats row. To design this properly we need to know what data we can use.

**Please provide:**

1. **Exact list of user-related counts/metrics you already return**  
   For the profile/user endpoint (e.g. `GET /api/users/{id}` or the one that returns full profile): which numeric stats do you currently send?  
   Please list **field name (e.g. `posts_count`)** and **short description**.

2. **Same metrics you could add easily**  
   Any counts you don’t expose yet but can add (e.g. videos count, groups count, followers, following, subscribers, etc.). Again: **field name** and **short description**.

3. **Response shape for stats**  
   Do you send these under a nested `stats` object (e.g. `data.stats.posts_count`) or at the root of the user object (e.g. `data.posts_count`)? If you have an example JSON snippet of the profile response (or the stats part only), that would help.

**What we use today (so you can align names if needed):**

- `posts_count` – number of posts by this user  
- `friends_count` – number of friends  
- `photos_count` – number of photos  

We’d like to support more stats in the same style (e.g. videos, music, groups, followers, following, subscribers, events, michango, etc.) as long as the backend can provide the count.

Thanks.

---

## Suggested stats to ask about (for your reference)

Use these as a checklist when you talk to backend or when they reply:

| Stat idea        | Description                              | Typical API field name   |
|------------------|------------------------------------------|--------------------------|
| Posts            | User’s posts                             | `posts_count` (have it)  |
| Friends          | Friends / connections                    | `friends_count` (have it)|
| Photos           | Photos in gallery                        | `photos_count` (have it) |
| Videos           | Videos uploaded / in gallery              | `videos_count`           |
| Music            | Music tracks / clips                      | `music_count`            |
| Groups           | Groups user is in or created              | `groups_count`           |
| Followers        | Users following this user                | `followers_count`        |
| Following        | Users this user follows                  | `following_count`       |
| Subscribers      | Paid / creator subscribers              | `subscribers_count`      |
| Michango         | Campaigns / donations related            | `michango_count`         |
| Live streams     | Live sessions                             | `live_count`             |
| Documents        | Documents uploaded                       | `documents_count`        |
| Shop items       | Products / listings (if you have shop)   | `shop_items_count`       |
| Mutual friends   | Already have as `mutual_friends_count`    | —                        |

---

## After you get the response

Once you have the list and field names:

1. Add the new fields to `ProfileStats` in `lib/models/profile_models.dart` (and parse them in `ProfileStats.fromJson`).
2. Extend the profile UI in `lib/screens/profile/profile_screen.dart`: add more `_buildStatItem(...)` calls (or a small configurable list) so we show only stats that are non-null and make sense for the product.

If you want, we can then add a follow-up task to implement the enriched stats section once the API contract is clear.
