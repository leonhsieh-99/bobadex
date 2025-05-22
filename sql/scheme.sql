-- SHOPS table
create table shops (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  name text not null,
  image_path text,
  rating float4 check (rating >= 0 and rating <= 5),
  is_favorite boolean default false,
  created_at timestamptz default now()
);

-- DRINKS table
create table drinks (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references shops(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  name text not null,
  rating int check (rating >= 1 and rating <= 5),
  favorite boolean default false,
  visibility text default 'private' check (visibility in ('private', 'friends', 'public')),
  created_at timestamptz default now()
);


-- Drink notes table (optional image + text)
create table drink_notes (
  id uuid primary key default gen_random_uuid(),
  drink_id uuid not null references drinks(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  note text not null,
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
  is_banner boolean default false, -- optional flag
  visibility text default 'private' check (visibility in ('private', 'friends', 'public')),
  created_at timestamptz default now()
);



-- FRIENDS table
create table user_friends (
  user_id uuid not null references users(id) on delete cascade,
  friend_id uuid not null references users(id) on delete cascade,
  primary key (user_id, friend_id)
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
