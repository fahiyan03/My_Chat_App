# my_chat_app

A new Flutter project created with FlutLab - https://flutlab.io

## Getting Started

A few resources to get you started if this is your first Flutter project:

- https://flutter.dev/docs/get-started/codelab
- https://flutter.dev/docs/cookbook

For help getting started with Flutter, view our
https://flutter.dev/docs, which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Getting Started: FlutLab - Flutter Online IDE

- How to use FlutLab? Please, view our https://flutlab.io/docs
- Join the discussion and conversation on https://flutlab.io/residents



## Supabase Database Setup (User Profiles and Messages Tables)

To enable real-time messaging and deletions, run the following commands in your Supabase SQL Editor:

```sql
-- *** Table definitions ***

create table if not exists public.profiles (
    id uuid references auth.users on delete cascade not null primary key,
    username varchar(24) not null unique,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,

    -- username should be 3 to 24 characters long containing alphabets, numbers and underscores
    constraint username_validation check (username ~* '^[A-Za-z0-9_]{3,24}$')
);
comment on table public.profiles is 'Holds all of users profile information';

create table if not exists public.messages (
    id uuid not null primary key default uuid_generate_v4(),
    profile_id uuid default auth.uid() references public.profiles(id) on delete cascade not null,
    content varchar(500) not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.messages is 'Holds individual messages within a chat room.';

-- *** Add tables to the publication to enable realtime ***
alter publication supabase_realtime add table public.messages;


-- Function to create a new row in profiles table upon signup
-- Also copies the username value from metadata
create or replace function handle_new_user() returns trigger as $$
    begin
        insert into public.profiles(id, username)
        values(new.id, new.raw_user_meta_data->>'username');

        return new;
    end;
$$ language plpgsql security definer;

-- Trigger to call `handle_new_user` when new user signs up
create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function handle_new_user();
```

## Supabase Database Setup (Chat Rooms, Participants, and Message Access Control)

```sql

-- *** Table definitions ***

create table if not exists public.rooms (
    id uuid not null primary key default uuid_generate_v4(),
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.rooms is 'Holds chat rooms';

create table if not exists public.room_participants (
    profile_id uuid references public.profiles(id) on delete cascade not null,
    room_id uuid references public.rooms(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    primary key (profile_id, room_id)
);
comment on table public.room_participants is 'Relational table of users and rooms.';

alter table public.messages
add column room_id uuid references public.rooms(id) on delete cascade not null;

-- *** Add tables to the publication to enable realtime ***

alter publication supabase_realtime add table public.room_participants;

-- *** Security definer functions ***

-- Returns true if the signed in user is a participant of the room
create or replace function is_room_participant(room_id uuid)
returns boolean as $$
  select exists(
    select 1
    from room_participants
    where room_id = is_room_participant.room_id and profile_id = auth.uid()
  );
$$ language sql security definer;


-- *** Row level security polities ***


alter table public.profiles enable row level security;
create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);


alter table public.rooms enable row level security;
create policy "Users can view rooms that they have joined" on public.rooms for select using (is_room_participant(id));


alter table public.room_participants enable row level security;
create policy "Participants of the room can view other participants." on public.room_participants for select using (is_room_participant(room_id));


alter table public.messages enable row level security;
create policy "Users can view messages on rooms they are in." on public.messages for select using (is_room_participant(room_id));
create policy "Users can insert messages on rooms they are in." on public.messages for insert with check (is_room_participant(room_id) and profile_id = auth.uid());


-- Creates a new room with the user and another user in it.
-- Will return the room_id of the created room
-- Will return a room_id if there were already a room with those participants
create or replace function create_new_room(other_user_id uuid) returns uuid as $$
    declare
        new_room_id uuid;
    begin
        -- Check if room with both participants already exist
        with rooms_with_profiles as (
            select room_id, array_agg(profile_id) as participants
            from room_participants
            group by room_id               
        )
        select room_id
        into new_room_id
        from rooms_with_profiles
        where create_new_room.other_user_id=any(participants)
        and auth.uid()=any(participants);


        if not found then
            -- Create a new room
            insert into public.rooms default values
            returning id into new_room_id;

            -- Insert the caller user into the new room
            insert into public.room_participants (profile_id, room_id)
            values (auth.uid(), new_room_id);

            -- Insert the other_user user into the new room
            insert into public.room_participants (profile_id, room_id)
            values (other_user_id, new_room_id);
        end if;

        return new_room_id;
    end
$$ language plpgsql security definer;

```

## Supabase Database Setup (User-Owned Message Updates)

```sql

-- Allow users to update their own messages
CREATE POLICY "Users can update own messages" ON public.messages
FOR UPDATE
TO authenticated
USING (auth.uid() = profile_id)
WITH CHECK (auth.uid() = profile_id);

```


## Supabase Database Setup (Self-Deletion Policy for Messages)

```sql
-- Allow users to delete their own messages
CREATE POLICY "Users can delete own messages" ON public.messages
FOR DELETE
TO authenticated
USING (auth.uid() = profile_id);

```

## Supabase Database Setup (Replicate Messages Events in Realtime Publication)

```sql
-- 1. This ensures the DELETE event includes the ID so the recipient knows what to remove
ALTER TABLE public.messages REPLICA IDENTITY FULL;

-- 2. This "refreshes" the publication settings for just this table
-- Use this specific syntax to avoid the "already a member" error
ALTER PUBLICATION supabase_realtime SET TABLE messages;


```
