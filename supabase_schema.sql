-- SQL schema setup for Supabase Postgres Database

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE (Linked to Supabase Auth)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL DEFAULT '',
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'worker', 'admin', 'manager')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow individual read access" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Allow individual update" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Allow admins to view all users" ON public.users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 2. PROPERTIES TABLE
CREATE TABLE public.properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    owner_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow property owners to view" ON public.properties
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Allow managers and admins to view all properties" ON public.properties
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- 3. ROOMS TABLE
CREATE TABLE public.rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow property owners to view rooms" ON public.rooms
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.properties p 
            WHERE p.id = property_id AND p.owner_id = auth.uid()
        )
    );

CREATE POLICY "Allow operations staff to view rooms" ON public.rooms
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- 4. APPLIANCES & ASSETS TABLE
CREATE TABLE public.appliances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Appliance', 'Furniture', 'Plumbing', 'Electrical', 'HVAC')),
    status TEXT NOT NULL DEFAULT 'Healthy',
    room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.appliances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read access to room appliances" ON public.appliances
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.rooms r
            JOIN public.properties p ON r.property_id = p.id
            WHERE r.id = room_id AND p.owner_id = auth.uid()
        )
    );

CREATE POLICY "Allow operational staff to view appliances" ON public.appliances
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- 5. WORKERS PROFILE TABLE
CREATE TABLE public.workers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    specialty TEXT NOT NULL,
    rating NUMERIC(3, 2) DEFAULT 5.0,
    vehicle_info TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.workers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to worker profiles" ON public.workers
    FOR SELECT TO authenticated USING (true);

-- 6. JOBS (MAINTENANCE REQUESTS) TABLE
CREATE TABLE public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    description TEXT NOT NULL,
    trade_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    schedule_date_time TIMESTAMP WITH TIME ZONE NOT NULL,
    address TEXT NOT NULL,
    customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    worker_id UUID REFERENCES public.workers(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow customers to view their own jobs" ON public.jobs
    FOR SELECT USING (auth.uid() = customer_id);

CREATE POLICY "Allow customers to insert their own jobs" ON public.jobs
    FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Allow workers to view their assigned jobs" ON public.jobs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.workers w
            WHERE w.id = worker_id AND w.user_id = auth.uid()
        )
    );

CREATE POLICY "Allow workers to update assigned jobs" ON public.jobs
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.workers w
            WHERE w.id = worker_id AND w.user_id = auth.uid()
        )
    );

CREATE POLICY "Allow admins/managers to view/edit all jobs" ON public.jobs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- 7. JOB IMAGES TABLE
CREATE TABLE public.job_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.job_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow view access to associated job images" ON public.job_images
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.jobs j
            WHERE j.id = job_id AND (
                j.customer_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM public.workers w 
                    WHERE w.id = j.worker_id AND w.user_id = auth.uid()
                ) OR
                EXISTS (
                    SELECT 1 FROM public.users u
                    WHERE u.id = auth.uid() AND u.role IN ('admin', 'manager')
                )
            )
        )
    );

-- 8. PRODUCTS (MARKETPLACE) TABLE
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    price NUMERIC(10, 2) NOT NULL,
    image_url TEXT NOT NULL,
    category TEXT NOT NULL,
    inventory_count INT NOT NULL DEFAULT 0,
    is_reserved BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to products" ON public.products
    FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Allow admins/managers to edit products" ON public.products
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- 9. WISHLISTS TABLE
CREATE TABLE public.wishlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(customer_id, product_id)
);

ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow individual wishlist management" ON public.wishlists
    FOR ALL USING (auth.uid() = customer_id);

-- INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_properties_owner ON public.properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_rooms_property ON public.rooms(property_id);
CREATE INDEX IF NOT EXISTS idx_appliances_room ON public.appliances(room_id);
CREATE INDEX IF NOT EXISTS idx_jobs_customer ON public.jobs(customer_id);
CREATE INDEX IF NOT EXISTS idx_jobs_worker ON public.jobs(worker_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs(status);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
