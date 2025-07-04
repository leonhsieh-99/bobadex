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

create table achievements (
  id serial primary key,
  name text not null,
  description text,
  icon_path text,        -- Path to the badge icon (local or remote)
  criteria jsonb,        -- Optional: JSON to describe requirements
  is_hidden boolean default false,
  display_order int default 0
);

create table user_achievements (
  id serial primary key,
  user_id uuid not null references users(id),
  achievement_id int not null references achievements(id),
  unlocked boolean default false,
  progress int default 0,         -- For achievements that require progress
  unlocked_at timestamptz,          -- When achievement was unlocked
  pinned boolean default false,   -- For showing on profile
  unique (user_id, achievement_id)
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
