# How Google Search Works — Full Technical Architecture

A comprehensive reference covering Google's search infrastructure: from crawling billions of pages to serving results in ~0.25 seconds. Updated with information from Google's official documentation, the 2024 API leak, 2023 antitrust trial testimony, and engineering publications.

---

## 1) Getting & Organising Data (Crawling + Storage)

This is where Google collects the web and prepares it for use.

### 1.1 Googlebot & Trawler

**Trawler** is Google's internal crawling and fetching system. It fetches web pages, manages redirects, HTTP headers, SSL certificates, and respects `robots.txt` rules. It collects detailed statistics for each page retrieved.

**Harpoon** acts as a client interface to Trawler, enabling other internal services to trigger fetches on demand (e.g., URL inspection requests from Google Search Console).

**Googlebot** is the public-facing name for the crawler fleet:

- Runs on a massive distributed infrastructure of commodity hardware
- Uses an algorithmic process to determine which sites to crawl, how often, and how many pages to fetch
- Supports HTTP/2 for improved crawling efficiency
- Respects `robots.txt` and cannot access pages requiring authentication
- **File size limit**: Reduced from 15MB to 2MB per resource in 2025 (an 86.7% decrease), driven by the computational cost of AI Overviews

> Googlebot is like a fleet of robots continuously browsing the internet 24/7, visiting billions of pages.

### 1.2 URL Discovery

URLs are discovered through three primary mechanisms:

1. **Revisiting previously known pages** and following outbound links
2. **Sitemaps** submitted by site owners
3. **Link discovery** from crawled pages pointing to new URLs

Google knows about **trillions of URLs** but can only index billions -- selection is a core engineering challenge.

### 1.3 Crawl Budget

Crawl budget is defined per hostname, with limits on how much time crawlers can spend on any single site:

- **Dynamic crawl budgeting** (introduced May 2025): Budget can change daily based on site performance
- Influenced by server response time, site importance, and content change frequency
- The **URL Frontier** maintains a prioritized queue of pages to visit

### 1.4 Web Rendering Service (WRS)

After Trawler fetches the initial HTML, the page is passed to the **Web Rendering Service (WRS)**:

- A headless browser environment based on a recent version of Chrome
- Executes JavaScript and renders the full DOM as a user's device would
- **Caches resources (JS, CSS) for up to 30 days** to conserve crawl budget
- Internal rendering component: **HtmlrenderWebkitHeadless** (identified in the leaked API documentation)

### 1.5 The Caffeine Architecture

**Before Caffeine** (pre-2010): Crawling and indexing operated as batch processes. Googlebot would crawl pages, process them as a batch, and documents had to wait until the entire batch completed before appearing in results.

**After Caffeine** (2010+): Google shifted to continuous, incremental indexing. When a page is crawled, it is processed through the entire indexing pipeline and pushed live nearly instantly. The web is analyzed in small portions and the index is updated continuously on a global basis.

### 1.6 Cleaning & Organising

Raw web data is messy, so Google:

- Removes duplicates (clusters similar pages, selects a "canonical" version)
- Filters spam/malicious pages (via **SpamBrain** neural network)
- Extracts useful parts (text, titles, links, keywords, metadata)

### 1.7 Structuring the Data

Content is broken into structured pieces:

- **Words** -> tokens (for the inverted index)
- **Pages** -> documents (with metadata, signals, and embeddings)
- **Links** -> relationships between pages (for PageRank and authority signals)

> At this stage, the web becomes machine-readable, not just human-readable.

---

## 2) Processing & Indexing Data

This is where Google understands and prepares data for fast lookup.

### 2.1 The Indexing Pipeline (Alexandria)

**Alexandria** is Google's core indexing system. The pipeline processes crawled and rendered pages through several stages:

1. **Content Analysis**: Text, images, videos, and metadata (`<title>` tags, alt attributes) are analyzed
2. **Tokenization**: Content is broken into tokens for the inverted index
3. **Signal Collection**: Language, geographic relevance, usability metrics, freshness signals, and quality signals are gathered
4. **Deduplication**: Similar pages are clustered and a canonical (most representative) version is selected
5. **DocJoin**: Components merge document-level data together (`IndexingDocjoinerDataVersion`)

### 2.2 Building the Inverted Index

Google uses a patented inverted index with two key components:

- A database of text elements (tokens)
- Numerical pointers to documents containing those tokens

> Word -> List of pages containing that word

Example:

```
"bank" -> [page1, page45, page876]
"loan" -> [page12, page45, page300]
```

The **tokenspace repository** uses a data structure allowing insertions at one end and deletions from the other. Updated documents are inserted as new versions while earlier versions are invalidated (placed in a garbage collection list, not immediately deleted).

Documents are also split into **multivector representations** -- each document is segmented into multiple semantic segments, each with its own embedding, for higher retrieval accuracy.

### 2.3 Index Tiers (SegIndexer & TeraGoogle)

**SegIndexer** stratifies documents into index tiers based on quality and importance:

| Tier | Description |
|------|-------------|
| **TYPE_HIGH_QUALITY** | Base documents -- served from fast in-memory systems |
| **TYPE_MEDIUM_QUALITY** | Supplemental tier |
| **TYPE_LOW_QUALITY** | "Blackhole" documents -- rarely served |

**TeraGoogle** is a secondary indexing system for documents that live on disk long-term (lower-tier content not frequently accessed).

### 2.4 Index Size & Scale

From the 2023 antitrust trial (testimony of VP of Search Pandu Nayak):

| Metric | Value |
|--------|-------|
| Index size | ~**400 billion documents** (as of 2020) |
| Storage | Over **100 million gigabytes** |
| Publicly visible pages | At least **3.98 billion unique pages** |
| System modules | ~2,596 modules with 14,014 attributes (stored as protocol buffers) |

Documents are **truncated at a max cap of tokens** in the ranking system (Mustang), which is why placing important content near the beginning of a page matters.

### 2.5 Ranking Preparation (Pre-computed Scores)

Before you even search, Google evaluates pages using:

- **PageRank** (link importance / authority)
- **Content relevance** (keywords, structure, headings)
- **Freshness** (publication date, update frequency)
- **User signals** (aggregated click behavior via NavBoost)
- **Quality scores** (site-level authority via Firefly)

Each page gets scores stored ahead of time.

### 2.6 Semantic Understanding (Modern AI Layer)

Google also:

- Understands **meaning** (not just keywords) using BERT, MUM, and neural matching
- Connects synonyms ("car" = "vehicle") via RankBrain
- Interprets intent ("best bank" vs "what is a bank")
- Creates **dense vector embeddings** for approximate nearest neighbor search

> This is where search becomes "smart," not just fast.

### 2.7 Freshness Mechanisms

Multiple date types are tracked per document:

- **bylineDate**: Explicitly set publication date
- **syntacticDate**: Extracted from URLs or page titles
- **semanticDate**: Derived from content analysis, anchors, and related documents

The **"Query Deserves Freshness" (QDF)** system detects when recent content should be prioritized (breaking news, current events, recent reviews).

### 2.8 Mobile-First Indexing

Content is indexed and ranked based primarily on the mobile version of pages. Ranking signals (page titles, performance, internal links) are analyzed from the mobile version. This became the default for all sites.

### 2.9 Storage Infrastructure

| System | Purpose |
|--------|---------|
| **Colossus** | Next-gen distributed file system (successor to GFS). Stores exabytes. Metadata in Bigtable allows 100x scaling over largest GFS clusters. |
| **Bigtable** | Structured storage for web indexing, analytics, and many Google services. Built on Colossus and Chubby Lock Service. |
| **Spanner** | Globally distributed database used for some ranking infrastructure components. |
| **MapReduce** | (And successors) Large-scale batch computation for parsing, link analysis, indexing, and feature extraction. |

Data is compressed and split across thousands of machines globally. No single server holds "the internet."

---

## 3) Serving Data (Query -> Results in ~0.25 seconds)

This is the part you experience.

### 3.1 Query Understanding

When a query arrives, it passes through several understanding stages:

**Step 1: Spelling Correction**
Using words found while crawling the web and processing billions of user queries to identify misspellings and likely corrections.

**Step 2: Query Expansion**
Adding synonyms, related terms, and semantic equivalents to increase recall.

**Step 3: Semantic Parsing**
Creating multiple query representations:

- **Lexical form** for BM25 matching
- **Dense embedding form** for vector search
- **Entity form** for Knowledge Graph matching
- **Task form** for determining output type (web, images, videos, news, etc.)

**Step 4: Intent Classification**
RankBrain handles synonym resolution, ambiguity, meaning, and significance -- especially for new queries, long-tail keywords, and voice search.

### 3.2 Query Fan-Out & Retrieval

The system performs **query fan-out**, exploding input into multiple subqueries targeting different intent dimensions. These run in parallel:

| Index | What it searches |
|-------|-----------------|
| **Web index** | Parallel BM25 (lexical) + ANN vector search across shards |
| **Knowledge Graph** | Entity fact retrieval via graph traversal |
| **YouTube** | Video transcripts via multimodal embedding spaces |
| **Shopping** | Commerce-specific product feeds |
| **Specialty indexes** | Scholar, Flights, Maps, News (intent-dependent) |

### 3.3 The Serving Pipeline (SuperRoot, Mustang, Ascorer)

**SuperRoot** is the central orchestration system coordinating query processing across servers. It bridges indexed data and the serving phase triggered by each user query.

**Mustang** is the primary scoring, ranking, and serving system. The pipeline:

1. Web server sends query to **index servers** (each containing a shard of the inverted index)
2. Queries parallelize across multiple servers; results are merged
3. **Ascorer** (primary ranking algorithm) generates initial rankings
4. **Twiddlers** (re-ranking functions) run after Ascorer to adjust scores
5. **SnippetBrain** generates snippets for display

### 3.4 Re-Ranking: The Twiddler Layer

Twiddlers are corrective mini-algorithms providing final editorial control:

| Twiddler | Function |
|----------|----------|
| **NavBoost** | Click-based re-ranking (most important -- see 3.5) |
| **FreshnessTwiddler** | Boosts content recency |
| **QualityBoost** | Modifies scores for quality signals |
| **RealTimeBoost** | Incorporates trending signals and real-time query spikes |

### 3.5 NavBoost (User Interaction Signals)

NavBoost is one of the most important ranking systems, operational since ~2005:

- Uses a **rolling 13-month window** of aggregated user click data
- Classifies clicks: **badClicks** (pogo-sticking), **goodClicks** (extended dwell time), **lastLongestClicks** (strongest satisfaction signal)
- **"Squashing" functions** normalize click data to prevent viral spikes or fraud from manipulating rankings
- Dramatically reduces candidate sets from tens of thousands down to a few hundred for final ranking
- **Instant Glue**: A fast variant operating on 24-hour windows with ~10-minute latency for breaking news
- Data is segmented by **geographic location and device type**

The **Glue system** extends NavBoost beyond web results to entire SERP elements, aggregating clicks, hovers, scrolls, and swipes into unified engagement metrics. It determines whether rich features (knowledge panels, image carousels, featured snippets) appear. Powers **"Whole-Page Ranking"** -- optimizing complete SERP layouts.

### 3.6 All Major Ranking Systems

**Active Systems:**

| System | Year | Function |
|--------|------|----------|
| **PageRank** | 1998 | Link analysis -- evaluates how pages link to determine authority. Core since founding. Still active but now one signal among many. |
| **RankBrain** | 2015 | ML system understanding word-concept relationships. Returns relevant content even without exact keyword matches. Key for new/ambiguous queries. |
| **Neural Matching** | 2018 | Maps concepts in queries to concepts in pages using neural embeddings. Covers ~30% of queries. |
| **BERT** | 2019 | Bidirectional Encoder Representations from Transformers. Understands how word combinations express different meanings and intent. |
| **Passage Ranking** | 2021 | Identifies individual sections/passages within pages for relevance, not just whole-page relevance. |
| **MUM** | 2021 | Multitask Unified Model. 1000x more powerful than BERT. Multimodal (text + images). Used for specific applications, not general ranking. |
| **SpamBrain** | Ongoing | Neural network spam detection. Identifies spam content, link spam, low-quality sites. Continuously trained. |
| **Helpful Content System** | 2024 | Integrated into core ranking (March 2024). Promotes original, helpful, people-first content. |
| **Reviews System** | Ongoing | Rewards high-quality reviews with insightful analysis and original research. |
| **Site Diversity** | Ongoing | Generally limits two listings per domain in top results. |

**Retired (integrated into core):**

| System | Year | Absorbed |
|--------|------|----------|
| **Panda** | 2011 | Quality content (integrated 2015) |
| **Penguin** | 2012 | Link spam (integrated 2016) |
| **Hummingbird** | 2013 | Query understanding (superseded by BERT/MUM) |

### 3.7 How Ranking Systems Work Together

The ranking pipeline is layered:

```
Query arrives
  |
  v
[1] Traditional signals (content, links, PageRank) -- remove spam & irrelevant
  |
  v
[2] Ascorer -- generates initial scores using hundreds of signals
  |
  v
[3] Neural systems (BERT, Neural Matching, RankBrain, Passage Ranking) -- re-rank for semantic understanding
  |
  v
[4] Twiddlers -- final adjustments (NavBoost clicks, freshness, quality)
  |
  v
[5] SpamBrain -- filters throughout the pipeline
  |
  v
[6] SuperRoot -- orchestrates final merge and snippet generation
  |
  v
Results served (~0.25 seconds)
```

### 3.8 Caching (Speed Boost)

Multi-layer caching for common queries:

- **LRU caches** at the shard level
- **In-memory cached structures** for hot queries
- **CDN-level caching** for static assets
- Results for popular queries may already be pre-computed and served from the nearest data center

### 3.9 Distributed Architecture & Fault Tolerance

From Google's seminal 2003 paper "Web Search for a Planet":

- Clusters of **15,000+ commodity PCs** with fault-tolerant software
- Superior performance at a fraction of the cost of high-end servers
- Index is **sharded** using document partitioning (each new document affects only one shard)
- Queries parallelize across shards; results are merged (merging is cheap compared to searching)
- Multiple data centers worldwide -- if an entire data center disconnects, service continues from others

---

## 4) The AI Layer (2024-2026)

Google's most significant evolution: AI directly integrated into the search pipeline.

### 4.1 AI Overviews

Launched broadly in 2024, expanded to 200+ countries by May 2025. Uses a custom **Gemini model** tightly integrated into the search stack:

- Not a separate product bolted on -- a retrieval-augmented layer built directly into the serving pipeline
- Single-shot generation with fixed-length token budgets
- Top candidates from the traditional retrieval pipeline are fed into the Gemini model
- Results undergo E-E-A-T scoring, content safety constraints, freshness weighting, and **snippet extractability**

### 4.2 AI Mode

Introduced March 2025, expanded with Gemini 3 (November 2025):

- Uses **Gemini 2.0** (later **Gemini 3** -- first time a Gemini model shipped to Search on launch day)
- Multi-turn retrieval cycles with context persistence across conversation turns
- Dynamically fetches additional evidence as needed
- More advanced reasoning, thinking, and multimodal capabilities

### 4.3 Deep Search

Handles complex, multi-faceted queries:

- Issues **hundreds of searches** in parallel
- Reasons across disparate pieces of information
- Creates expert-level, fully-cited reports in minutes

### 4.4 TPU Infrastructure

Google's AI search runs on custom **Tensor Processing Units (TPUs)**:

- **TPU v7 (Ironwood)** unveiled April 2025: 256-chip and 9,216-chip cluster configurations
- AI Overviews require LLM inference for every query, creating substantial new computational demands
- Key driver behind the 2025 crawl budget reductions (resource reallocation toward AI inference)

### 4.5 The Combined Pipeline (2025+)

The modern query flow:

```
1. Query arrives --> semantic parsing into multiple representations
2. Query fan-out to web index, Knowledge Graph, YouTube, Shopping, specialty indexes
3. Parallel BM25 + ANN vector search across shards
4. Results aggregated, deduplicated, quality-filtered
5. Traditional ranking (Ascorer + Twiddlers + NavBoost)
6. Top candidates fed to Gemini model for AI Overview synthesis
7. Both traditional blue links AND AI-generated overview returned
8. In AI Mode: multi-turn conversation with dynamic re-retrieval
```

---

## Scale Numbers

| Metric | Value |
|--------|-------|
| Daily searches | ~8.5-16.4 billion (~99,000/second) |
| Annual searches | 5+ trillion |
| Index size | ~400 billion documents, 100+ million GB |
| Known URLs | Trillions |
| Global market share | ~90.8% |
| Mobile share | 60-71% of all searches |
| Data centers | 12+ countries (massive expansion: $15B India, $9B Virginia, $9B Oklahoma) |
| Average response time | ~0.25 seconds |
| Queries per second | 100,000+ |

---

## Summary: The 3+1 Stage Model

### 1. Getting & Organising Data
- Googlebot/Trawler crawl the web continuously
- WRS renders JavaScript pages
- Content cleaned, deduplicated, structured
- Stored in Colossus/Bigtable distributed systems

### 2. Processing & Indexing Data
- Alexandria builds the inverted index
- SegIndexer tiers documents by quality
- Pre-compute rankings (PageRank, quality scores, NavBoost)
- BERT/MUM/Neural Matching understand meaning
- Distribute across thousands of servers globally

### 3. Serving Data
- Query parsed into multiple representations instantly
- Fan-out to parallel indexes (web, Knowledge Graph, YouTube, etc.)
- Ascorer + Twiddlers rank in real-time
- SnippetBrain generates summaries
- Results returned in ~0.25 seconds

### 4. AI Layer (2024+)
- Top candidates fed to Gemini model
- AI Overviews synthesize answers
- AI Mode enables multi-turn search conversations
- Deep Search handles complex research queries

---

## Key Insight

**90% of the work is done before you search.**

When you finally type something:

- It's not computing from scratch
- It's doing a super-fast **lookup + sort** against a pre-built, pre-scored index
- The AI layer adds synthesis on top, but retrieval is still the foundation

---

## Sources

- [Google: How Search Works (Official)](https://developers.google.com/search/docs/fundamentals/how-search-works)
- [Google Ranking Systems Guide (Official)](https://developers.google.com/search/docs/appearance/ranking-systems-guide)
- [Web Search for a Planet: The Google Cluster Architecture (2003)](https://research.google.com/archive/googlecluster-ieee.pdf)
- [Our New Search Index: Caffeine (Official Blog)](https://developers.google.com/search/blog/2010/06/our-new-search-index-caffeine)
- [A Peek Behind Colossus (Google Cloud Blog)](https://cloud.google.com/blog/products/storage-data-transfer/a-peek-behind-colossus-googles-file-system)
- [AI Search Architecture Deep Dive (iPullRank)](https://ipullrank.com/ai-search-manual/search-architecture)
- [Google Algorithm Leak Analysis (iPullRank)](https://ipullrank.com/google-algo-leak)
- [Google's Index Size: 400 Billion Docs (Zyppy)](https://zyppy.com/seo/google-index-size/)
- [NavBoost: How User Interactions Rank Websites (Hobo)](https://www.hobo-web.co.uk/navboost-how-google-uses-large-scale-user-interaction-data-to-rank-websites/)
- [Google Search System Design (System Design Handbook)](https://www.systemdesignhandbook.com/guides/google-search-system-design)
- [Google Indexing & Ranking: Court Documents (FratreSEO)](https://fratreseo.com/blog/how-google-indexing-and-ranking-works-information-from-court-documents/)
- [Google Leak Part 6: How Google Search Works (RESONEO)](https://www.resoneo.com/google-leak-part-6-how-does-google-search-work-a-deep-dive-into-google-leaks/)
- [RankBrain, BERT, MUM Evolution (HuskyHamster)](https://huskyhamster.com/blog/13/rankbrain-bert-mum-evolution-of-googles-core-algorithm)
- [Google AI Ranking: RankBrain, BERT, DeepRank & NavBoost (SEO Kreativ)](https://www.seo-kreativ.de/en/blog/google-ai-ranking-system/)
- [Google Search Statistics 2025 (Global Tech Stack)](https://www.globaltechstack.com/google-search-statistics/)
- [AI Mode and AI Overviews Updates (Google Blog)](https://blog.google/products-and-platforms/products/search/ai-mode-ai-overviews-updates/)
- [Google Brings Gemini 3 to Search (Google Blog)](https://blog.google/products-and-platforms/products/search/gemini-3-search-ai-mode/)
- [Crawling December: Googlebot Resources (Official)](https://developers.google.com/search/blog/2024/12/crawling-december-resources)
- [Google Slashes Web Crawl Limit by 86.7% (PPC Land)](https://ppc.land/google-slashes-web-crawl-limit-by-86-7-as-cost-pressures-mount/)
