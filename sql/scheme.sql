-- Create users table
create table users (
  id uuid primary key references auth.users(id),
  username text unique not null,
  created_at timestamptz default now()
);

-- Create shops table
create table shops (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  name text not null,
  rating float,
  favorite boolean default false,
  image_path text,
  location text,
  created_at timestamptz default now()
);

-- Create drinks table
create table drinks (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid references shops(id),
  name text not null,
  rating float,
  favorite boolean default false,
  created_at timestamptz default now()
);
