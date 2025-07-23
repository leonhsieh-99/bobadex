-- SHOPS table
create table shops (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  name text not null,
  rating float4 check (rating >= 0 and rating <= 5),
  is_favorite boolean default false,
  notes text,
  pinned_drink_id uuid,
  place_id text -- FUTURE USE (MAYBE)
  brand_slug text references ref.brands(slug)
  created_at timestamptz default now()
);

-- DRINKS table
create table drinks (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references shops(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  name text not null,
  rating int check (rating >= 1 and rating <= 5),
  notes text,
  is_favorite boolean default false,
  visibility text default 'private' check (visibility in ('private', 'friends', 'public')),
  created_at timestamptz default now()
);


-- Drink images table (pure gallery uploads)
create table shop_media (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references shops(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  drink_id uuid references drinks(id) on delete set null, -- optional association
  image_path text not null,
  comment text default null,
  is_banner boolean default false,
  visibility text default 'private' check (visibility in ('private', 'friends', 'public')),
  created_at timestamptz default now()
);

-- Users table
create table users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text not null,
  profile_image_path text,
  bio text,
  created_at timestamptz default now()
);

-- User settings table
create table user_settings (
  user_id uuid primary key references users(id) on delete cascade,
  theme_slug text default 'grey',
  grid_columns int default 2,
  created_at timestamptz default now()
);

-- FRIENDS table
CREATE TABLE friendships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id uuid REFERENCES users(id) ON DELETE CASCADE,
  addressee_id uuid REFERENCES users(id) ON DELETE CASCADE,
  status text CHECK (status IN ('pending', 'accepted', 'rejected')) NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  accepted_at timestamptz;
  UNIQUE (requester_id, addressee_id)
);

CREATE TABLE achievements (
    uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    icon_path TEXT,
    depends_on jsonb,
    is_hidden BOOLEAN DEFAULT FALSE,
    display_order int default 0
);

-- User Achievements: reference achievements.uuid
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    achievement_uuid UUID NOT NULL REFERENCES achievements(uuid),
    unlocked BOOLEAN DEFAULT FALSE,
    unlocked_at TIMESTAMPTZ,
    pinned BOOLEAN DEFAULT FALSE,
    progress INTEGER DEFAULT 0
);


create table feed_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  shop_id uuid references shops(id) on delete cascade,
  brand_slug text references brands(slug) on delete cascade,
  event_type text,  -- 'shop_add', 'drink_add', 'achievement', etc.
  created_at timestamptz default now(),
  payload jsonb,       -- flexible, stores extra event data
  is_backfill boolean default false
);

create table reports (
  id uuid primary key default gen_random_uuid(),
  reported_by uuid references users(id) not null,
  content_type text not null,         -- 'photo', 'comment', etc.
  content_id uuid not null,           -- id of reported item
  reason text not null,               -- category
  message text,                       -- optional, extra user message
  created_at timestamptz not null default now()
);


-- Common filter/join targets
create index on drinks(shop_id);
create index on drink_notes(drink_id);
create index on shop_media(shop_id);
create index on shop_media(drink_id);
create index on shop_media(user_id);

-- Optional: for filtering by visibility
create index on shop_media(visibility);
create index on drinks(visibility);

-- Index for fast querying
create index on feed_events(user_id, created_at desc);
create index on reports(content_type, content_id);

----------READ ONLY TABLES------------

-- Brands Table
create table brands (
  slug text primary key,                -- e.g. 'gong-cha'
  display text,
  wikidata text,                        -- Q-ID when known
  aliases text[],                       -- lower-case spellings
  logo_url text,
  icon_path text,
);

CREATE TABLE brand_aliases (
  id serial PRIMARY KEY,
  brand_slug text REFERENCES brands(slug) ON DELETE CASCADE,
  normalized_name text NOT NULL UNIQUE    -- e.g. 'gongcha', 'gong-cha', '贡茶'
);

create table brand_staging (
  id uuid primary key default gen_random_uuid(),
  suggested_name text not null,
  location text,
  submitted_by uuid,
  created_at timestamp with time zone default timezone('utc', now()),
  status text default 'pending',
  merged_slug text,  -- slug in brands if merged/approved
  raw_payload jsonb,
  source text default 'user',
  duplicates int default 1
);


-- Brand Locations Table
create table ref.brand_locations (
  brand_slug text references ref.brands(slug) on delete cascade,
  osm_id bigint,                        -- null when scraped
  geom geometry(Point, 4326),
  last_seen timestamptz,
  suspect boolean default false,
  primary key (brand_slug, osm_id)
);

-- Boundaries Table (cities, counties, etc.)
create table ref.boundaries (
  id bigserial primary key,
  name text,
  level int,                            -- 6 = county, 8 = city
  geom geometry(MultiPolygon, 4326)
);

CREATE INDEX boundary_gix ON ref.boundaries USING GIST (geom);
