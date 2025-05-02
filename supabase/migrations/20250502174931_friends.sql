-- Create friends table in auth schema
CREATE TABLE auth.friends (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    -- Ensure a user can't be friends with themselves
    CONSTRAINT no_self_friendship CHECK (user_id != friend_id),
    -- Ensure each friendship is unique (regardless of order)
    CONSTRAINT unique_friendship UNIQUE (user_id, friend_id)
);

-- Add indexes for better query performance
CREATE INDEX friends_user_id_idx ON auth.friends(user_id);
CREATE INDEX friends_friend_id_idx ON auth.friends(friend_id);

-- Add RLS policies
ALTER TABLE auth.friends ENABLE ROW LEVEL SECURITY;

-- Policy to allow users to view their own friendships
CREATE POLICY "Users can view their own friendships"
    ON auth.friends
    FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Policy to allow users to create friendships
CREATE POLICY "Users can create friendships"
    ON auth.friends
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy to allow users to delete their own friendships
CREATE POLICY "Users can delete their own friendships"
    ON auth.friends
    FOR DELETE
    USING (auth.uid() = user_id OR auth.uid() = friend_id);
