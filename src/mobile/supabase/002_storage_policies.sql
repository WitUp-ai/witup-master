-- =====================================================
-- Draw2Toy Storage Bucket Policies
-- Run AFTER creating the "drawings" bucket in Dashboard
-- =====================================================

-- Policy: Allow authenticated users to upload to their own folder
-- Path pattern: drawings/{user_id}/*
CREATE POLICY "Users can upload to own folder" ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'drawings' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Policy: Allow authenticated users to update their own files
CREATE POLICY "Users can update own files" ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'drawings' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Policy: Allow authenticated users to delete their own files
CREATE POLICY "Users can delete own files" ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'drawings' AND
        (storage.foldername(name))[1] = auth.uid()::text
    );

-- Policy: Allow public read access to all drawings
-- (This makes images publicly viewable via URL)
CREATE POLICY "Public read access for drawings" ON storage.objects
    FOR SELECT
    TO public
    USING (bucket_id = 'drawings');

-- =====================================================
-- ALTERNATIVE: If you want private access only
-- Remove the public policy above and use this instead:
-- =====================================================
-- CREATE POLICY "Users can view own files" ON storage.objects
--     FOR SELECT
--     TO authenticated
--     USING (
--         bucket_id = 'drawings' AND
--         (storage.foldername(name))[1] = auth.uid()::text
--     );
