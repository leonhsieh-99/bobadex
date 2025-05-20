-- SHOPS table
create table shops (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  name text not null,
  image_url text,
  rating float4 check (rating >= 0 and rating <= 5),
  is_favorite boolean default false,
  created_at timestamptz default now()
);

-- DRINKS table
create table drinks (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid references shops(id) on delete cascade,
  name text not null,
  rating float4 check (rating >= 0 and rating <= 5),
  is_favorite boolean default false,
  created_at timestamptz default now()
);

-- FRIENDS table
create table friends (
  user_id uuid references users(id) on delete cascade,
  friend_id uuid references users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, friend_id)
);
