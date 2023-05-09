--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2
-- Dumped by pg_dump version 12.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: console_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.console_user (
    create_time timestamp with time zone DEFAULT now() NOT NULL,
    disable_time timestamp with time zone DEFAULT '1970-01-01 00:00:00+00'::timestamp with time zone NOT NULL,
    email character varying(255) NOT NULL,
    id uuid NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    password bytea,
    role smallint DEFAULT 4 NOT NULL,
    update_time timestamp with time zone DEFAULT now() NOT NULL,
    username character varying(128) NOT NULL,
    CONSTRAINT console_user_password_check CHECK ((length(password) < 32000)),
    CONSTRAINT console_user_role_check CHECK ((role >= 1))
);


ALTER TABLE public.console_user OWNER TO postgres;

--
-- Name: group_edge; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_edge (
    source_id uuid NOT NULL,
    "position" bigint NOT NULL,
    update_time timestamp with time zone DEFAULT now() NOT NULL,
    destination_id uuid NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    CONSTRAINT group_edge_destination_id_check CHECK ((destination_id <> '00000000-0000-0000-0000-000000000000'::uuid)),
    CONSTRAINT group_edge_source_id_check CHECK ((source_id <> '00000000-0000-0000-0000-000000000000'::uuid))
);


ALTER TABLE public.group_edge OWNER TO postgres;

--
-- Name: groups; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.groups (
    id uuid NOT NULL,
    creator_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    avatar_url character varying(512),
    lang_tag character varying(18) DEFAULT 'en'::character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    edge_count integer DEFAULT 0 NOT NULL,
    max_count integer DEFAULT 100 NOT NULL,
    create_time timestamp with time zone DEFAULT now() NOT NULL,
    update_time timestamp with time zone DEFAULT now() NOT NULL,
    disable_time timestamp with time zone DEFAULT '1970-01-01 00:00:00+00'::timestamp with time zone NOT NULL,
    CONSTRAINT groups_check CHECK (((edge_count >= 1) AND (edge_count <= max_count))),
    CONSTRAINT groups_max_count_check CHECK ((max_count >= 1)),
    CONSTRAINT groups_state_check CHECK ((state >= 0))
);


ALTER TABLE public.groups OWNER TO postgres;

--
-- Name: leaderboard; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.leaderboard (
    id character varying(128) NOT NULL,
    authoritative boolean DEFAULT false NOT NULL,
    sort_order smallint DEFAULT 1 NOT NULL,
    operator smallint DEFAULT 0 NOT NULL,
    reset_schedule character varying(64),
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    create_time timestamp with time zone DEFAULT now() NOT NULL,
    category smallint DEFAULT 0 NOT NULL,
    description character varying(255) DEFAULT ''::character varying NOT NULL,
    duration integer DEFAULT 0 NOT NULL,
    end_time timestamp with time zone DEFAULT '1970-01-01 00:00:00+00'::timestamp with time zone NOT NULL,
    join_required boolean DEFAULT false NOT NULL,
    max_size integer DEFAULT 100000000 NOT NULL,
    max_num_score integer DEFAULT 1000000 NOT NULL,
    title character varying(255) DEFAULT ''::character varying NOT NULL,
    size integer DEFAULT 0 NOT NULL,
    start_time timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT leaderboard_category_check CHECK ((category >= 0)),
    CONSTRAINT leaderboard_duration_check CHECK ((duration >= 0)),
    CONSTRAINT leaderboard_max_num_score_check CHECK ((max_num_score > 0)),
    CONSTRAINT leaderboard_max_size_check CHECK ((max_size > 0))
);


ALTER TABLE public.leaderboard OWNER TO postgres;

--
-- Name: leaderboard_record; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.leaderboard_record (
    leaderboard_id character varying(128) NOT NULL,
    owner_id uuid NOT NULL,
    username character varying(128),
    score bigint DEFAULT 0 NOT NULL,
    subscore bigint DEFAULT 0 NOT NULL,
    num_score integer DEFAULT 1 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    create_time timestamp with time zone DEFAULT now() NOT NULL,
    update_time timestamp with time zone DEFAULT now() NOT NULL,
    expiry_time timestamp with time zone DEFAULT '1970-01-01 00:00:00+00'::timestamp with time zone NOT NULL,
    max_num_score integer DEFAULT 1000000 NOT NULL,
    CONSTRAINT leaderboard_record_max_num_score_check CHECK ((max_num_score > 0)),
    CONSTRAINT leaderboard_record_num_score_check CHECK ((num_score >= 0)),
    CONSTRAINT leaderboard_record_score_check CHECK ((score >= 0)),
    CONSTRAINT leaderboard_record_subscore_check CHECK ((subscore >= 0))
);


ALTER TABLE public.leaderboard_record OWNER TO postgres;

--
-- Name: message; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message (
    id uuid NOT NULL,
    code smallint DEFAULT 0 NOT NULL,
    sender_id uuid NOT NULL,
    username character varying(128) NOT NULL,
    stream_mode smallint NOT NULL,
    stream_subject uuid NOT NULL,
    stream_descriptor uuid NOT NULL,
    stream_label character varying(128) NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    create_time timestamp with time zone DEFAULT now() NOT NULL,
    update_time timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.message OWNER TO postgres;

--
-- Name: migration_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migration_info (
    id text NOT NULL,
    applied_at timestamp with time zone
);


ALTER TABLE public.migration_info OWNER TO postgres;

--
-- Name: notification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    subject character varying(255) NOT NULL,
    content jsonb DEFAULT '{}'::jsonb NOT NULL,
    code smallint NOT NULL,
    sender_id uuid NOT NULL,
    create_time timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notification OWNER TO postgres;

--
-- Name: purchase; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.purchase (
    create_time timestamp with time zone DEFAULT now() NOT NULL,
    environment smallint DEFAULT 0 NOT NULL,
    product_id character varying(512) NOT NULL,
    purchase_time timestamp with time zone DEFAULT now() NOT NULL,
    raw_response jsonb DEFAULT '{}'::jsonb NOT NULL,
    store smallint DEFAULT 0 NOT NULL,
    transaction_id character varying(512) NOT NULL,
    update_time timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid,
    CONSTRAINT purchase_transaction_id_check CHECK ((length((transaction_id)::text) > 0))
);


ALTER TABLE public.purchase OWNER TO postgres;

--
-- Name: storage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.storage (
    collection character varying(128) NOT NULL,
    key character varying(128) NOT NULL,
    user_id uuid NOT NULL,
    value jsonb DEFAULT '{}'::jsonb NOT NULL,
    version character varying(32) NOT NULL,
    read smallint DEFAULT 1 NOT NULL,
    write smallint DEFAULT 1 NOT NULL,
    create_time timestamp with time zone DEFAULT now() NOT NULL,
    update_time timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT storage_read_check CHECK ((read >= 0)),
    CONSTRAINT storage_write_check CHECK ((write >= 0))
);


ALTER TABLE public.storage OWNER TO postgres;

--
-- Name: user_device; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_device (
    id character varying(128) NOT NULL,
    user_id uuid NOT NULL,
    preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    push_token_amazon character varying(512) DEFAULT ''::character varying NOT NULL,
    push_token_android character varying(512) DEFAULT ''::character varying NOT NULL,
    push_token_huawei character varying(512) DEFAULT ''::character varying NOT NULL,
    push_token_ios character varying(512) DEFAULT ''::character varying NOT NULL,
    push_token_web character varying(512) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.user_device OWNER TO postgres;

--
-- Name: user_edge; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_edge (
    source_id uuid NOT NULL,
    "position" bigint NOT NULL,
    update_time timestamp with time zone DEFAULT now() NOT NULL,
    destination_id uuid NOT NULL,
    state smallint DEFAULT 0 NOT NULL,
    CONSTRAINT user_edge_destination_id_check CHECK ((destination_id <> '00000000-0000-0000-0000-000000000000'::uuid)),
    CONSTRAINT user_edge_source_id_check CHECK ((source_id <> '00000000-0000-0000-0000-000000000000'::uuid))
);


ALTER TABLE public.user_edge OWNER TO postgres;

--
-- Name: user_tombstone; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_tombstone (
    user_id uuid NOT NULL,
    create_time timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_tombstone OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    username character varying(128) NOT NULL,
    display_name character varying(255),
    avatar_url character varying(512),
    lang_tag character varying(18) DEFAULT 'en'::character varying NOT NULL,
    location character varying(255),
    timezone character varying(255),
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    wallet jsonb DEFAULT '{}'::jsonb NOT NULL,
    email character varying(255),
    password bytea,
    facebook_id character varying(128),
    google_id character varying(128),
    gamecenter_id character varying(128),
    steam_id character varying(128),
    custom_id character varying(128),
    edge_count integer DEFAULT 0 NOT NULL,
    create_time timestamp with time zone DEFAULT now() NOT NULL,
    update_time timestamp with time zone DEFAULT now() NOT NULL,
    verify_time timestamp with time zone DEFAULT '1970-01-01 00:00:00+00'::timestamp with time zone NOT NULL,
    disable_time timestamp with time zone DEFAULT '1970-01-01 00:00:00+00'::timestamp with time zone NOT NULL,
    facebook_instant_game_id character varying(128),
    apple_id character varying(128),
    CONSTRAINT users_edge_count_check CHECK ((edge_count >= 0)),
    CONSTRAINT users_password_check CHECK ((length(password) < 32000))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: wallet_ledger; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wallet_ledger (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    changeset jsonb NOT NULL,
    metadata jsonb NOT NULL,
    create_time timestamp with time zone DEFAULT now() NOT NULL,
    update_time timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.wallet_ledger OWNER TO postgres;

--
-- Data for Name: console_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.console_user (create_time, disable_time, email, id, metadata, password, role, update_time, username) FROM stdin;
\.


--
-- Data for Name: group_edge; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_edge (source_id, "position", update_time, destination_id, state) FROM stdin;
\.


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.groups (id, creator_id, name, description, avatar_url, lang_tag, metadata, state, edge_count, max_count, create_time, update_time, disable_time) FROM stdin;
\.


--
-- Data for Name: leaderboard; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.leaderboard (id, authoritative, sort_order, operator, reset_schedule, metadata, create_time, category, description, duration, end_time, join_required, max_size, max_num_score, title, size, start_time) FROM stdin;
\.


--
-- Data for Name: leaderboard_record; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.leaderboard_record (leaderboard_id, owner_id, username, score, subscore, num_score, metadata, create_time, update_time, expiry_time, max_num_score) FROM stdin;
\.


--
-- Data for Name: message; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.message (id, code, sender_id, username, stream_mode, stream_subject, stream_descriptor, stream_label, content, create_time, update_time) FROM stdin;
\.


--
-- Data for Name: migration_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.migration_info (id, applied_at) FROM stdin;
20180103142001_initial_schema.sql	2021-08-12 14:14:43.636369+00
20180805174141-tournaments.sql	2021-08-12 14:14:43.653548+00
20200116134800-facebook-instant-games.sql	2021-08-12 14:14:43.662202+00
20200615102232-apple.sql	2021-08-12 14:14:43.668054+00
20201005180855-console.sql	2021-08-12 14:14:43.703343+00
20210416090601-purchase.sql	2021-08-12 14:14:43.722609+00
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification (id, user_id, subject, content, code, sender_id, create_time) FROM stdin;
4156b58e-be33-4ffa-a1a5-74fa6e22d368	4c0003f0-3e3f-4b49-8aad-10db98f2d3dc	user11 wants to add you as a friend	{"username": "user11"}	-2	5264dc23-a339-40db-bb84-e0849ded4e68	2021-11-03 15:29:36.601859+00
3fcb0ec7-e95b-4214-a819-e9f3d8024c48	6a10eac1-35c9-4f47-acd7-2814e257574b	user11 wants to add you as a friend	{"username": "user11"}	-2	5264dc23-a339-40db-bb84-e0849ded4e68	2021-11-03 15:42:54.781977+00
521ace63-10bd-4fad-95e2-39ecf1394eb4	ac943677-b181-4113-98ec-6586fe2ab9cb	user11 wants to add you as a friend	{"username": "user11"}	-2	5264dc23-a339-40db-bb84-e0849ded4e68	2021-11-03 15:57:19.391245+00
a70eec4b-6538-4466-b394-c4a5f890847d	f5dde9e0-dcd1-4788-9de2-b3ca0670fff6	user11 wants to add you as a friend	{"username": "user11"}	-2	5264dc23-a339-40db-bb84-e0849ded4e68	2021-11-03 16:00:14.848041+00
\.


--
-- Data for Name: purchase; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.purchase (create_time, environment, product_id, purchase_time, raw_response, store, transaction_id, update_time, user_id) FROM stdin;
\.


--
-- Data for Name: storage; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.storage (collection, key, user_id, value, version, read, write, create_time, update_time) FROM stdin;
drawing	1646657737035_witAngel-vis	5264dc23-a339-40db-bb84-e0849ded4e68	{"url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1646657737035_witAngel-vis.png", "json": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1646657737035_witAngel-vis.json", "version": 0, "displayname": "witAngel-vis"}	9aac7a9a17dd105c4d484b479d52b318	2	1	2022-03-07 11:59:12.610989+00	2022-03-07 11:59:12.610989+00
home	Heerhugowaard	a337d949-894b-4503-a58d-3f947c8298da	{"url": "/home/stock/portalDonkerBlauw.png", "posX": 0, "posY": 0, "username": "userTest"}	da4db970d799bdf9b8e6c3bfe6dd03b5	2	1	2022-02-18 14:59:03.191798+00	2022-02-18 14:59:03.191798+00
home	Amsterdam	f42eb28f-9f4d-476c-9788-2240bac4cf48	{"url": "home/stock/portalGifGroen.png", "posX": 143.16, "posY": -178.99, "version": 0, "username": "user33"}	7e2c81e1e8cbb3b1d6be84bd7e017392	2	1	2021-12-13 14:37:50.681635+00	2022-02-18 15:02:58.001119+00
home	Amsterdam	f5dde9e0-dcd1-4788-9de2-b3ca0670fff6	{"url": "home/stock/portalRood.png", "username": "user55"}	bc6872bc46488e7b9590925b95560836	2	1	2022-02-11 14:55:06.287533+00	2022-02-18 15:03:24.090696+00
drawing	1646662781948_olijfgroenkrab	5264dc23-a339-40db-bb84-e0849ded4e68	{"url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1646662781948_olijfgroenkrab.png", "json": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1646662781948_olijfgroenkrab.json", "version": 0, "displayname": "olijfgroenkrab"}	0b1004206f891aeccdec46ea2b2f1dfd	2	1	2022-03-07 13:19:03.878348+00	2022-03-07 13:19:03.878348+00
drawing	zilverGemeenschappelijke-vlieg	f42eb28f-9f4d-476c-9788-2240bac4cf48	{"url": "drawing/f42eb28f-9f4d-476c-9788-2240bac4cf48/zilverGemeenschappelijke-vlieg.png", "json": "drawing/f42eb28f-9f4d-476c-9788-2240bac4cf48/zilverGemeenschappelijke-vlieg.json", "status": "", "previewUrl": "https://d3hkghsa3z4n1z.cloudfront.net/fit-in/64x64/drawing/f42eb28f-9f4d-476c-9788-2240bac4cf48/zilverGemeenschappelijke-vlieg.png?signature=05cc740e7c36cb016d87251469eec75a5c9287cbe045195329998a365cb0966e"}	ae2261de39ef53f424a34843279bf10d	2	1	2021-12-14 13:58:47.62876+00	2022-02-02 21:17:48.773135+00
drawing	groenblauwtoekan	4ced8bff-d79c-4842-b2bd-39e9d9aa597e	{"url": "drawing/4ced8bff-d79c-4842-b2bd-39e9d9aa597e/groenblauwtoekan.png", "json": "drawing/4ced8bff-d79c-4842-b2bd-39e9d9aa597e/groenblauwtoekan.json", "previewUrl": "https://d3hkghsa3z4n1z.cloudfront.net/fit-in/64x64/drawing/4ced8bff-d79c-4842-b2bd-39e9d9aa597e/groenblauwtoekan.png?signature=d4432aa68b1de8b25a554c9b3a150a0f8b82701d7ea9e421b953ca57c86cddda", "displayname": "12345"}	8085dfd964794524917722e1396cca37	2	1	2021-12-14 13:55:17.15678+00	2022-02-02 21:17:49.495968+00
addressbook	addressbook_4c0003f0-3e3f-4b49-8aad-10db98f2d3dc	4c0003f0-3e3f-4b49-8aad-10db98f2d3dc	{"addressbook": []}	247e6735883b9170eed471dd411095cb	2	1	2022-02-20 13:03:43.131046+00	2022-02-20 16:06:53.401159+00
liked	liked_b9ae6807-1ce1-4b71-a8a3-f5958be4d340	b9ae6807-1ce1-4b71-a8a3-f5958be4d340	{"liked": []}	8d76ddb8d8f68cb6391d119ad02657ce	2	1	2022-02-17 15:09:26.930181+00	2022-02-17 15:09:26.930181+00
drawing	groenLynx	4ced8bff-d79c-4842-b2bd-39e9d9aa597e	{"url": "drawing/4ced8bff-d79c-4842-b2bd-39e9d9aa597e/groenLynx.png", "json": "drawing/4ced8bff-d79c-4842-b2bd-39e9d9aa597e/groenLynx.json", "previewUrl": "https://d3hkghsa3z4n1z.cloudfront.net/fit-in/64x64/drawing/4ced8bff-d79c-4842-b2bd-39e9d9aa597e/groenLynx.png?signature=0b715456ad3a06edbae7e64cb09f25f68d434f385257a790a7d1baeaae7a3637"}	3a24743482bd0611ac96ff473aefc65d	2	1	2022-02-04 18:37:22.188364+00	2022-02-20 14:39:06.218802+00
addressbook	addressbook_5264dc23-a339-40db-bb84-e0849ded4e68	5264dc23-a339-40db-bb84-e0849ded4e68	{"addressbook": []}	247e6735883b9170eed471dd411095cb	2	1	2022-02-08 11:31:58.076164+00	2022-02-20 20:19:17.627137+00
addressbook	addressbook_f5dde9e0-dcd1-4788-9de2-b3ca0670fff6	f5dde9e0-dcd1-4788-9de2-b3ca0670fff6	{"addressbook": []}	247e6735883b9170eed471dd411095cb	2	1	2022-02-11 14:08:50.307681+00	2022-02-23 20:46:43.409652+00
addressbook	addressbook_4ced8bff-d79c-4842-b2bd-39e9d9aa597e	4ced8bff-d79c-4842-b2bd-39e9d9aa597e	{"addressbook": []}	247e6735883b9170eed471dd411095cb	2	1	2022-02-09 10:40:08.302563+00	2022-03-07 08:43:21.220713+00
home	test	b9ae6807-1ce1-4b71-a8a3-f5958be4d340	{"posX": "123", "posY": "123"}	d0694b439ec844e38177a9c9f98fe301	1	1	2022-02-07 15:24:25.475513+00	2022-02-07 15:24:25.475513+00
liked	liked_fcbcc269-a109-4a4b-a570-5ccafc5308d8	fcbcc269-a109-4a4b-a570-5ccafc5308d8	{"liked": []}	8d76ddb8d8f68cb6391d119ad02657ce	2	1	2022-02-08 01:51:58.466727+00	2022-02-08 01:51:58.466727+00
stopmotion	groenkraan	4bd9378d-8b5b-4ea3-b683-6c3324792afe	{"jpeg": "stopmotion/4bd9378d-8b5b-4ea3-b683-6c3324792afe/groenkraan.jpeg", "json": "stopmotion/4bd9378d-8b5b-4ea3-b683-6c3324792afe/groenkraan.json", "status": "trash"}	c00bb1610ed06da18aaaa5d56155a39e	1	1	2021-10-07 19:33:52.979022+00	2021-10-22 13:43:20.045919+00
location	home	5264dc23-a339-40db-bb84-e0849ded4e68	{"name": "heyyA", "posX": 13, "posY": 9}	d88b88d554fe97d851634d6653e639c5	2	1	2021-12-01 20:08:44.87254+00	2021-12-01 20:15:20.644182+00
location	wereldwijd	5264dc23-a339-40db-bb84-e0849ded4e68	{"posX": 79, "posY": 30}	335bdb31a53c46b97b3ff4151065cc6e	2	1	2021-12-01 20:24:31.354978+00	2021-12-01 20:24:31.354978+00
world	AZC Amsterdam	5264dc23-a339-40db-bb84-e0849ded4e68	{"posX": 21, "posY": 9}	b8f4f74ac94e52f7eef7e29c22297ca5	2	1	2021-12-01 20:26:10.647109+00	2021-12-01 20:26:10.647109+00
home	Amsterdam	4ced8bff-d79c-4842-b2bd-39e9d9aa597e	{"url": "home/stock/portalBlauw.png", "posX": 184.83, "posY": 312.66, "version": 0, "username": "user22"}	fef13a8a864d64d0f8844e8d619eaf9d	2	1	2022-01-12 12:07:59.842656+00	2022-02-18 15:01:32.878834+00
Liked	Liked_b9ae6807-1ce1-4b71-a8a3-f5958be4d340	b9ae6807-1ce1-4b71-a8a3-f5958be4d340	{"drawing/5264dc23-a339-40db-bb84-e0849ded4e68/geelCoral.png": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/geelCoral.png", "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/4_blauwSpotlijster.png": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/4_blauwSpotlijster.png"}	1905299bb4c4512858e51b53d554fd34	2	1	2022-01-29 09:28:23.589287+00	2022-01-29 09:28:23.589287+00
addressbook	addressbook_b9ae6807-1ce1-4b71-a8a3-f5958be4d340	b9ae6807-1ce1-4b71-a8a3-f5958be4d340	{"addressbook": []}	247e6735883b9170eed471dd411095cb	2	1	2022-02-17 15:09:26.931619+00	2022-02-18 12:13:03.484427+00
home	Amsterdam	5264dc23-a339-40db-bb84-e0849ded4e68	{"url": "home/stock/portalDonkerBlauw.png", "posX": 228.16, "posY": 57.66, "version": 0, "userName": "user11", "username": "user11"}	abe7e2d6d2a8926490bc27c067cecc22	2	1	2022-01-12 12:31:53.578276+00	2022-02-18 15:01:45.27838+00
liked	liked_4c0003f0-3e3f-4b49-8aad-10db98f2d3dc	4c0003f0-3e3f-4b49-8aad-10db98f2d3dc	{"liked": []}	8d76ddb8d8f68cb6391d119ad02657ce	2	1	2022-02-20 13:03:43.463586+00	2022-02-20 13:03:43.463586+00
liked	liked_f5dde9e0-dcd1-4788-9de2-b3ca0670fff6	f5dde9e0-dcd1-4788-9de2-b3ca0670fff6	{"liked": [{"key": "groenblauwtoekan", "url": "drawing/4ced8bff-d79c-4842-b2bd-39e9d9aa597e/groenblauwtoekan.png", "user_id": "4ced8bff-d79c-4842-b2bd-39e9d9aa597e", "collection": "drawing"}, {"key": "groenLynx", "url": "drawing/4ced8bff-d79c-4842-b2bd-39e9d9aa597e/groenLynx.png", "user_id": "4ced8bff-d79c-4842-b2bd-39e9d9aa597e", "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "zilverGemeenschappelijke-vlieg", "url": "drawing/f42eb28f-9f4d-476c-9788-2240bac4cf48/zilverGemeenschappelijke-vlieg.png", "user_id": "f42eb28f-9f4d-476c-9788-2240bac4cf48", "collection": "drawing"}]}	086796e679abfa604789982eb94b96bc	2	1	2022-02-07 16:09:19.689542+00	2022-02-21 00:10:11.037388+00
liked	liked_9d1bf4cc-97f4-4bce-b350-84be7b526a9e	9d1bf4cc-97f4-4bce-b350-84be7b526a9e	{"liked": []}	8d76ddb8d8f68cb6391d119ad02657ce	2	1	2022-02-08 01:52:14.272883+00	2022-02-08 01:52:14.272883+00
drawing	zilverpinguïn	f84848e2-d354-455e-a4b9-0db6b9834ae0	{"url": "drawing/f84848e2-d354-455e-a4b9-0db6b9834ae0/0_zilverpinguÃ¯n.png", "json": "drawing/f84848e2-d354-455e-a4b9-0db6b9834ae0/0_zilverpinguÃ¯n.json", "status": "trash", "version": 0, "previewUrl": "https://d3hkghsa3z4n1z.cloudfront.net/fit-in/64x64/drawing/f84848e2-d354-455e-a4b9-0db6b9834ae0/0_zilverpinguÃ¯n.png?signature=7cb628b635cc4e6507b45c8e35d45204785cedfad2c15b97ce25bc98f92caf34"}	b89613caee83d939b23506580bcec360	1	1	2022-01-19 16:43:12.528629+00	2022-01-31 09:00:54.668915+00
liked	liked_f42eb28f-9f4d-476c-9788-2240bac4cf48	5264dc23-a339-40db-bb84-e0849ded4e68	{}	99914b932bd37a50b983c5e7c90ae93b	2	1	2022-02-07 16:08:29.964647+00	2022-02-07 16:08:29.964647+00
addressbook	addressbook_f42eb28f-9f4d-476c-9788-2240bac4cf48	f42eb28f-9f4d-476c-9788-2240bac4cf48	{"addressbook": []}	247e6735883b9170eed471dd411095cb	2	1	2022-02-08 11:56:37.610493+00	2022-02-17 11:34:58.110429+00
picture	testPicture	b9ae6807-1ce1-4b71-a8a3-f5958be4d340	{"url": "picture/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/testPicture.png", "previewUrl": "https://d3hkghsa3z4n1z.cloudfront.net/fit-in/64x64/picture/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/testPicture.png?signature=a687f7eee833917f3842571b3108e836db0c9774432b4a4230da1876db74dbe2"}	964a11249e0247eeba8eddc9be680714	2	1	2022-01-17 16:23:21.113083+00	2022-02-02 20:20:15.154297+00
allLike	allLike_5264dc23-a339-40db-bb84-e0849ded4e68	5264dc23-a339-40db-bb84-e0849ded4e68	{"drawing/5264dc23-a339-40db-bb84-e0849ded4e68/geelCoral.png": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/geelCoral.png", "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/1_cyaankaaiman.png": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/1_cyaankaaiman.png", "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/4_blauwSpotlijster.png": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/4_blauwSpotlijster.png", "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/2_groenblauwZarigüeya.png": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/2_groenblauwZarigüeya.png", "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/5_blauwSpotlijster_changedTitle.png": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/5_blauwSpotlijster_changedTitle.png"}	1b8d731c4079b3f9fd3a05d9f5515066	2	1	2022-01-20 13:46:34.137567+00	2022-01-20 13:49:12.572683+00
home	Amsterdam	4c0003f0-3e3f-4b49-8aad-10db98f2d3dc	{"url": "home/4c0003f0-3e3f-4b49-8aad-10db98f2d3dc/3_current.png", "username": "user88"}	0579e989a16f3e228a10d49d13dc3da6	2	1	2022-01-19 16:31:43.951718+00	2022-01-19 16:32:27.744363+00
home	Drachten	f84848e2-d354-455e-a4b9-0db6b9834ae0	{"url": "home/f84848e2-d354-455e-a4b9-0db6b9834ae0/1_current.png", "username": "user1010"}	47ca88a97abce95a831f1e8c6d9869a9	2	1	2022-01-19 16:33:52.846427+00	2022-01-19 16:34:04.528869+00
drawing	test upload	b9ae6807-1ce1-4b71-a8a3-f5958be4d340	{"url": "drawing/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/test upload.jpg", "status": "trash", "previewUrl": "https://d3hkghsa3z4n1z.cloudfront.net/fit-in/64x64/drawing/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/test upload.jpg?signature=6cf70163373658dc5f5046b23e7449b562e52e84fad1ef1e015014c487b60b0e"}	453da1930326678c9ee5b6a5c85798e3	1	1	2022-01-14 12:09:58.21272+00	2022-01-31 09:00:52.650756+00
stopmotion	kastanjebruinLama	b9ae6807-1ce1-4b71-a8a3-f5958be4d340	{"jpeg": "stopmotion/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/kastanjebruinLama.jpeg", "json": "stopmotion/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/kastanjebruinLama.json", "status": "trash", "previewUrl": "https://d3hkghsa3z4n1z.cloudfront.net/fit-in/64x64/?signature=d767ccefc272a086df5eca3260e6ccdfd82293b9702dbe1d4b9f7b36d1191564"}	ab71a2f1a9ff6db57f3c3b7c37e3cc32	1	1	2021-09-16 15:20:05.462464+00	2022-01-31 09:00:54.983218+00
addressbook	addressbook_9d1bf4cc-97f4-4bce-b350-84be7b526a9e	9d1bf4cc-97f4-4bce-b350-84be7b526a9e	{"addressbook": []}	247e6735883b9170eed471dd411095cb	2	1	2022-02-15 13:50:53.79261+00	2022-02-15 13:50:53.79261+00
Liked	Liked_5264dc23-a339-40db-bb84-e0849ded4e68	5264dc23-a339-40db-bb84-e0849ded4e68	{"drawing/5264dc23-a339-40db-bb84-e0849ded4e68/geelCoral.png": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/geelCoral.png", "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/4_blauwSpotlijster.png": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/4_blauwSpotlijster.png"}	6ca76276ecd647bca55b597babb093a6	2	1	2022-01-28 19:39:23.467549+00	2022-02-04 18:47:42.673382+00
liked	liked_6a10eac1-35c9-4f47-acd7-2814e257574b	6a10eac1-35c9-4f47-acd7-2814e257574b	{"liked": [{"key": "1644634171559_LIEFDE", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1644634171559_LIEFDE.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}, {"key": "magentaGemeenschappelijke-vlieg", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/magentaGemeenschappelijke-vlieg.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "1644682970599_witDoornhaai-haai", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1644682970599_witDoornhaai-haai.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}]}	c250d62d212c4a007d3a193e2483cd33	2	1	2022-02-07 16:32:09.354656+00	2022-02-15 15:20:03.82469+00
drawing	groenhamster	b9ae6807-1ce1-4b71-a8a3-f5958be4d340	{"url": "drawing/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/groenhamster.png", "json": "drawing/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/groenhamster.json", "previewUrl": "https://d3hkghsa3z4n1z.cloudfront.net/fit-in/64x64/drawing/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/groenhamster.png?signature=f70498ec7ba40adeb590aab924cb1c2b1e066f0216b9d813e4a9d1a917f572fa"}	75de8154c95ec24d38cee89a63051ecc	2	1	2022-01-04 13:59:49.17475+00	2022-02-02 20:20:13.954165+00
addressbook	addressbook_6a10eac1-35c9-4f47-acd7-2814e257574b	6a10eac1-35c9-4f47-acd7-2814e257574b	{"addressbook": [{"user_id": "9d1bf4cc-97f4-4bce-b350-84be7b526a9e"}, {"user_id": "f42eb28f-9f4d-476c-9788-2240bac4cf48"}, {"user_id": "f5dde9e0-dcd1-4788-9de2-b3ca0670fff6"}, {"user_id": "4ced8bff-d79c-4842-b2bd-39e9d9aa597e"}]}	a15e67b006ac4c07ab58a3986d1a3b76	2	1	2022-02-08 13:31:57.394267+00	2022-02-15 15:25:24.327407+00
liked	liked_5264dc23-a339-40db-bb84-e0849ded4e68	5264dc23-a339-40db-bb84-e0849ded4e68	{"liked": [{"key": "1643301959176_cyaanConejo", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1643301959176_cyaanConejo.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "magentaGemeenschappelijke-vlieg", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/magentaGemeenschappelijke-vlieg.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "1644634171559_LIEFDE", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1644634171559_LIEFDE.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}, {"key": "1644682970599_witDoornhaai-haai", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1644682970599_witDoornhaai-haai.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}, {"key": "groenhamster", "url": "drawing/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/groenhamster.png", "user_id": "b9ae6807-1ce1-4b71-a8a3-f5958be4d340", "collection": "drawing"}, {"key": "zilverGemeenschappelijke-vlieg", "url": "drawing/f42eb28f-9f4d-476c-9788-2240bac4cf48/zilverGemeenschappelijke-vlieg.png", "user_id": "f42eb28f-9f4d-476c-9788-2240bac4cf48", "collection": "drawing"}, {"key": "1646657737035_witAngel-vis", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1646657737035_witAngel-vis.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}, {"key": "1646657737035_witAngel-vis", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1646657737035_witAngel-vis.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}]}	384e172bc88485c252f510de65d22b34	2	1	2022-01-26 12:02:11.802412+00	2022-03-07 14:04:27.95379+00
home	Amsterdam	6a10eac1-35c9-4f47-acd7-2814e257574b	{"url": "home/stock/portalGeel.png", "version": 0, "username": "user44"}	56e7c476cbfc85cc27a471bfe3fe0fc4	2	1	2022-02-18 14:33:09.715422+00	2022-02-18 15:02:13.470793+00
drawing	1646323166530_cyaanLui	f5dde9e0-dcd1-4788-9de2-b3ca0670fff6	{"url": "drawing/f5dde9e0-dcd1-4788-9de2-b3ca0670fff6/0_1646323166530_cyaanLui.png", "json": "drawing/f5dde9e0-dcd1-4788-9de2-b3ca0670fff6/0_1646323166530_cyaanLui.json", "version": 0, "displayname": "cyaanLui"}	b019d85e596edee7ae38fdc9b72c8037	2	1	2022-03-03 15:59:31.078468+00	2022-03-03 15:59:31.078468+00
liked	liked_4ced8bff-d79c-4842-b2bd-39e9d9aa597e	4ced8bff-d79c-4842-b2bd-39e9d9aa597e	{"liked": [{"key": "magentaGemeenschappelijke-vlieg", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/magentaGemeenschappelijke-vlieg.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "witMurene", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/witMurene.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "collection": "drawing"}, {"key": "1644682970599_witDoornhaai-haai", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1644682970599_witDoornhaai-haai.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}, {"key": "1644634171559_LIEFDE", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1644634171559_LIEFDE.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}, {"key": "groenLynx", "url": "drawing/4ced8bff-d79c-4842-b2bd-39e9d9aa597e/groenLynx.png", "user_id": "4ced8bff-d79c-4842-b2bd-39e9d9aa597e", "collection": "drawing"}, {"key": "zilverGemeenschappelijke-vlieg", "url": "drawing/f42eb28f-9f4d-476c-9788-2240bac4cf48/zilverGemeenschappelijke-vlieg.png", "user_id": "f42eb28f-9f4d-476c-9788-2240bac4cf48", "collection": "drawing"}]}	27ad6f25c3fb1355868c9935dec681b3	2	1	2022-02-07 16:23:12.426865+00	2022-03-07 09:23:18.913724+00
liked	liked_f42eb28f-9f4d-476c-9788-2240bac4cf48	f42eb28f-9f4d-476c-9788-2240bac4cf48	{"liked": [{"key": "1644634171559_LIEFDE", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1644634171559_LIEFDE.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}, {"key": "1644682970599_witDoornhaai-haai", "url": "drawing/5264dc23-a339-40db-bb84-e0849ded4e68/0_1644682970599_witDoornhaai-haai.png", "user_id": "5264dc23-a339-40db-bb84-e0849ded4e68", "version": 0, "collection": "drawing"}, {"key": "groenLynx", "url": "drawing/4ced8bff-d79c-4842-b2bd-39e9d9aa597e/groenLynx.png", "user_id": "4ced8bff-d79c-4842-b2bd-39e9d9aa597e", "collection": "drawing"}, {"key": "zilverGemeenschappelijke-vlieg", "url": "drawing/f42eb28f-9f4d-476c-9788-2240bac4cf48/zilverGemeenschappelijke-vlieg.png", "user_id": "f42eb28f-9f4d-476c-9788-2240bac4cf48", "collection": "drawing"}]}	0a4ec8ae1cfdb55b08bd552711a2e0f3	2	1	2022-02-07 16:10:55.815439+00	2022-02-19 11:13:10.548427+00
\.


--
-- Data for Name: user_device; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_device (id, user_id, preferences, push_token_amazon, push_token_android, push_token_huawei, push_token_ios, push_token_web) FROM stdin;
\.


--
-- Data for Name: user_edge; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_edge (source_id, "position", update_time, destination_id, state) FROM stdin;
5264dc23-a339-40db-bb84-e0849ded4e68	1635953376592860133	2021-11-03 15:29:36.589951+00	4c0003f0-3e3f-4b49-8aad-10db98f2d3dc	1
4c0003f0-3e3f-4b49-8aad-10db98f2d3dc	1635953376592860133	2021-11-03 15:29:36.589951+00	5264dc23-a339-40db-bb84-e0849ded4e68	2
5264dc23-a339-40db-bb84-e0849ded4e68	1635954174777817466	2021-11-03 15:42:54.775994+00	6a10eac1-35c9-4f47-acd7-2814e257574b	1
6a10eac1-35c9-4f47-acd7-2814e257574b	1635954174777817466	2021-11-03 15:42:54.775994+00	5264dc23-a339-40db-bb84-e0849ded4e68	2
5264dc23-a339-40db-bb84-e0849ded4e68	1635955039384855111	2021-11-03 15:57:19.382243+00	ac943677-b181-4113-98ec-6586fe2ab9cb	1
ac943677-b181-4113-98ec-6586fe2ab9cb	1635955039384855111	2021-11-03 15:57:19.382243+00	5264dc23-a339-40db-bb84-e0849ded4e68	2
5264dc23-a339-40db-bb84-e0849ded4e68	1635955214844110295	2021-11-03 16:00:14.842449+00	f5dde9e0-dcd1-4788-9de2-b3ca0670fff6	1
f5dde9e0-dcd1-4788-9de2-b3ca0670fff6	1635955214844110295	2021-11-03 16:00:14.842449+00	5264dc23-a339-40db-bb84-e0849ded4e68	2
\.


--
-- Data for Name: user_tombstone; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_tombstone (user_id, create_time) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, display_name, avatar_url, lang_tag, location, timezone, metadata, wallet, email, password, facebook_id, google_id, gamecenter_id, steam_id, custom_id, edge_count, create_time, update_time, verify_time, disable_time, facebook_instant_game_id, apple_id) FROM stdin;
00000000-0000-0000-0000-000000000000		\N	\N	en	\N	\N	{}	{}	\N	\N	\N	\N	\N	\N	\N	0	2021-08-12 14:14:43.456588+00	2021-08-12 14:14:43.456588+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
ac943677-b181-4113-98ec-6586fe2ab9cb	user12	\N	\N	en	\N	\N	{"azc": "Amsterdam", "posX": 0, "posY": 0, "role": "speler", "user_id": "", "location": "home"}	{}	user12@vrolijkheid.nl	\\x24326124313024455259495239303063634648756b6c2e584e4b727875596d7174644f7856334d626a744873766174434d514142665a765a7a526a4f	\N	\N	\N	\N	\N	1	2021-10-25 08:52:38.990819+00	2021-11-03 15:57:19.382243+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
4bd9378d-8b5b-4ea3-b683-6c3324792afe	artworld1	\N	avatar/4bd9378d-8b5b-4ea3-b683-6c3324792afe/current.png	en	\N	\N	{"azc": "Amsterdam", "posX": 930, "posY": 918, "role": "speler", "user_id": "", "location": "home"}	{}	gebruiker1@devrolijkheid.nl	\\x243261243130247a34776a576e3533587848486a4b666b59787179512e4571786e6f374f325562685a45547a61377969484347646e516b646c64422e	\N	\N	\N	\N	\N	0	2021-10-06 13:50:01.144738+00	2021-10-06 14:03:48.748812+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
4ced8bff-d79c-4842-b2bd-39e9d9aa597e	user22	\N	avatar/stock/avatarPaars.png	en	\N	\N	{"azc": "Amsterdam", "posX": 0, "posY": 0, "role": "speler", "user_id": "", "location": "ArtworldAmsterdam"}	{}	user2@vrolijkheid.nl	\\x243261243130242e51706e4f454f4c575862494b596d6d79734e70694f754a6b2e4f776553507475794e69375838616b6b452e413655357731624f53	\N	\N	\N	\N	\N	0	2021-10-11 11:31:54.293367+00	2022-03-07 09:23:51.617338+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
f84848e2-d354-455e-a4b9-0db6b9834ae0	user1010	\N	avatar/f84848e2-d354-455e-a4b9-0db6b9834ae0/2_current.png	en	\N	\N	{"azc": "Drachten", "role": "kunstenaar"}	{}	user10@vrolijkheid.nl	\\x24326124313024512e62357357673745785a6671474b65622f31505565444d6e303131485934684c2f5a52562f706a577949324c3355783058336261	\N	\N	\N	\N	\N	0	2021-10-11 11:32:55.103998+00	2022-01-19 16:33:43.148638+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
f42eb28f-9f4d-476c-9788-2240bac4cf48	user33	\N	avatar/stock/avatarGroen.png	en	\N	\N	{"azc": "Amsterdam", "posX": -138.78334, "posY": 321.1, "role": "speler", "user_id": "", "location": "ArtworldAmsterdam"}	{}	user3@vrolijkheid.nl	\\x2432612431302438504e6338736163446655695953632e7a74776e494f62527551504b2e61503131474d6d4d574f57373263725a7672664262584871	\N	\N	\N	\N	\N	0	2021-10-11 11:32:02.048537+00	2022-03-02 14:15:07.237946+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
5a1f7399-b1d3-472b-98d0-f3df90cb43c6	user4	\N	avatar/5a1f7399-b1d3-472b-98d0-f3df90cb43c6/4.png	en	\N	\N	{"azc": "Amsterdam", "posX": 0, "posY": 0, "role": "speler", "user_id": "", "location": ""}	{}	user4@lindseyschaap.nl	\\x243261243130246a50347345354c6d537435454a324445686534654c2e4d7477556649707269456843534f2e37455861622e57314151794e36436f43	\N	\N	\N	\N	\N	0	2021-08-13 11:32:02.436283+00	2021-08-31 13:19:43.946117+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
9d1bf4cc-97f4-4bce-b350-84be7b526a9e	user77	\N	avatar/9d1bf4cc-97f4-4bce-b350-84be7b526a9e/3_current.png	en	\N	\N	{"azc": "Amsterdam", "posX": -16.078012, "posY": 157.52072, "role": "speler", "user_id": "", "location": "ArtworldAmsterdam"}	{}	user7@vrolijkheid.nl	\\x2432612431302450716c6465784c6c7a535330597150614e3044753875646a57783362336750456e533243413930705769585974774f4c794d4d6736	\N	\N	\N	\N	\N	0	2021-10-11 11:32:32.071128+00	2022-02-15 15:22:11.419801+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
b9ae6807-1ce1-4b71-a8a3-f5958be4d340	user1	\N	avatar/b9ae6807-1ce1-4b71-a8a3-f5958be4d340/current.png	en	\N	\N	{"azc": "Amsterdam", "posX": 749.59784, "posY": -448.1215, "role": "admin", "location": "ArtworldAmsterdam"}	{}	user1@lindseyschaap.nl	\\x2432612431302431656648696574382e416c736233704b4e6d723637756a73434b363167723061435643594a49754b435147574d4e78415571424d65	\N	\N	\N	\N	\N	0	2021-08-12 15:08:40.973779+00	2022-03-02 15:00:49.844668+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
daf9d417-ebd7-40f6-a2d2-6f7e7a5cd602	linjoe354354	\N	\N	en	\N	\N	{"azc": "Amsterdam", "posX": 0, "posY": 0, "role": "", "user_id": "", "location": ""}	{}	ik25345345@lindseyschaap.nl	\\x243261243130243455777464672e436e4b787545496f417a6c6f5a314f654657784135502f506f6c6f454a364d686555307945364a473761515a6775	\N	\N	\N	\N	\N	0	2021-08-13 11:40:09.124465+00	2021-08-13 11:40:09.124465+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
c2651be6-a535-4cef-903b-1bd462ddca3a	user3	\N	avatar/c2651be6-a535-4cef-903b-1bd462ddca3a/current.png	en	\N	\N	{"azc": "Amsterdam", "role": "kunstenaar"}	{}	user3@lindseyschaap.nl	\\x24326124313024646b6b396b4e514641326b532e585176354a72514b2e5a61536c7746545a6176335275584f785859772f41327447373531656a446d	\N	\N	\N	\N	\N	0	2021-08-13 11:31:54.844275+00	2021-09-16 15:22:49.255959+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
57a1deb4-6687-42ed-85e5-135fd6336567	user99	\N	\N	en	\N	\N	{"azc": "Amsterdam", "posX": 0, "posY": 0, "role": "speler", "user_id": "", "location": ""}	{}	user9@vrolijkheid.nl	\\x24326124313024664d666637722f484f535051773557754b3075565165306c37614576654651322f733172412f5969432f6834545476373177356536	\N	\N	\N	\N	\N	0	2021-10-11 11:32:47.030414+00	2021-10-11 11:32:47.032173+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
f95a226a-6c76-46fe-86b6-6a2353ebbdbb	watchdog	\N	\N	en	\N	\N	{"azc": "Amsterdam", "posX": 0, "posY": 0, "role": "speler", "user_id": "", "location": ""}	{}	watchdog@vrolijkheid.nl	\\x243261243130245836526339414b584b356c5448764e6d32356430672e2f534f704a75482f534558344663494a7056414265616d564b68773079714f	\N	\N	\N	\N	\N	0	2021-11-22 14:58:11.463323+00	2021-11-22 14:58:11.468503+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
fcbcc269-a109-4a4b-a570-5ccafc5308d8	user66	\N	avatar/fcbcc269-a109-4a4b-a570-5ccafc5308d8/current.png	en	\N	\N	{"azc": "Amsterdam", "posX": -157.57443, "posY": 18.174648, "role": "speler", "user_id": "", "location": "ArtworldAmsterdam"}	{}	user6@vrolijkheid.nl	\\x24326124313024614465364d49715564344a506c35414a2e4b6b5a716531636261732e496830715556362e5a7750434d2f506377333678346f583979	\N	\N	\N	\N	\N	0	2021-10-11 11:32:24.330988+00	2022-02-08 09:14:50.124413+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
b5b11afb-6e43-4977-bc97-dfe1fc6effe9	user2	\N	avatar/b5b11afb-6e43-4977-bc97-dfe1fc6effe9/current.png	en	\N	\N	{"azc": "Amsterdam", "posX": 913, "posY": 794, "role": "moderator", "user_id": "", "location": "home"}	{}	user2@lindseyschaap.nl	\\x243261243130246f707867377541744545517852342e4a4d63684c514f4f6531305a5735485968655532785a484e67556e6345377639537248447136	\N	\N	\N	\N	\N	0	2021-08-12 15:08:50.114272+00	2022-01-27 16:05:48.708326+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
4c0003f0-3e3f-4b49-8aad-10db98f2d3dc	user88	\N	avatar/4c0003f0-3e3f-4b49-8aad-10db98f2d3dc/3_current.png	en	\N	\N	{"azc": "Amsterdam", "posX": -35.383335, "posY": 883.9167, "role": "speler", "user_id": "", "location": "ArtworldAmsterdam"}	{}	user8@vrolijkheid.nl	\\x243261243130244f6d7243442e2e59664d3969327a3635617a6c72784f483545434636374a54555732676d6e6f4a63546247592e5747772f57344d79	\N	\N	\N	\N	\N	1	2021-10-11 11:32:40.118686+00	2022-02-20 15:49:07.236285+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
3395afeb-7e2c-4cf3-bca9-b4803e187f5c	linjoe3	\N	\N	en	\N	\N	{"azc": "Amsterdam", "posX": 0, "posY": 0, "role": "speler", "user_id": "", "location": ""}	{}	ik2@lindseyschaap.nl	\\x243261243130244f636d67466446397478644d383871764234697a334f6d4d4d663872596148494c59466b72714d79715333367a4a45736238373732	\N	\N	\N	\N	\N	0	2021-08-12 15:08:22.788579+00	2021-08-23 00:38:24.176603+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
54a0e072-dca2-4a5e-ba32-8ba44dada690	user5	\N	\N	en	\N	\N	{"azc": "Amsterdam", "posX": 0, "posY": 0, "role": "", "user_id": "", "location": ""}	{}	user5@lindseyschaap.nl	\\x24326124313024516548364545534f306c434d533548447a716836624f6841336866654639424c30616254303679475157786477322f384b6a45424b	\N	\N	\N	\N	\N	0	2021-08-13 11:34:09.967404+00	2021-08-13 11:34:09.967404+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
6a10eac1-35c9-4f47-acd7-2814e257574b	user44	\N	avatar/stock/avatarGeel.png	en	\N	\N	{"azc": "Amsterdam", "posX": -9.764147, "posY": -451.9965, "role": "speler", "user_id": "", "location": "ArtworldAmsterdam"}	{}	user4@vrolijkheid.nl	\\x243261243130244c33756d312f512f697365716d74342e6b316e6b37657735747273726a517557614a494961482f386834666b64616c794871426c53	\N	\N	\N	\N	\N	1	2021-10-11 11:32:10.391389+00	2022-03-02 14:13:05.981353+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
5264dc23-a339-40db-bb84-e0849ded4e68	user11	\N	avatar/5264dc23-a339-40db-bb84-e0849ded4e68/1_current.png	en	\N	\N	{"azc": "Amsterdam", "posX": -230, "posY": -160, "role": "speler", "user_id": "", "location": "ArtworldAmsterdam"}	{}	user1@vrolijkheid.nl	\\x243261243130242e54526e42365150503441343270424a386b6a462f2e562f473145776366543257336a3268484b2e535537756f7432723379773936	\N	\N	\N	\N	\N	4	2021-10-16 17:28:59.874284+00	2022-03-07 15:35:09.15849+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
a337d949-894b-4503-a58d-3f947c8298da	userTest	\N	/avatar/stock/avatarPaars.png	en	\N	\N	{"azc": "Heerhugowaard", "role": "speler"}	{}	usertest@vrolijkheid.nl	\\x24326124313024366d43466c4e474261796a67765261704a446e396365315536644f49516f7a3454324a3838336342716d42694b392e346674425136	\N	\N	\N	\N	\N	0	2022-02-18 14:59:03.186912+00	2022-02-18 14:59:03.189033+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
f5dde9e0-dcd1-4788-9de2-b3ca0670fff6	user55	\N	avatar/stock/avatarBlauw.png	en	\N	\N	{"azc": "Amsterdam", "posX": -99.75005, "posY": -39.99993, "role": "speler", "user_id": "", "location": "ArtworldAmsterdam"}	{}	user5@vrolijkheid.nl	\\x24326124313024653953767a423368464e353334456f6f624e347a322e6b73333268324a3545415942302f35533475795158703870334956596f514b	\N	\N	\N	\N	\N	1	2021-10-11 11:32:17.129953+00	2022-03-03 16:00:03.434395+00	1970-01-01 00:00:00+00	1970-01-01 00:00:00+00	\N	\N
\.


--
-- Data for Name: wallet_ledger; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wallet_ledger (id, user_id, changeset, metadata, create_time, update_time) FROM stdin;
\.


--
-- Name: console_user console_user_email_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.console_user
    ADD CONSTRAINT console_user_email_uniq UNIQUE (email);


--
-- Name: console_user console_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.console_user
    ADD CONSTRAINT console_user_pkey PRIMARY KEY (id);


--
-- Name: console_user console_user_username_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.console_user
    ADD CONSTRAINT console_user_username_uniq UNIQUE (username);


--
-- Name: group_edge group_edge_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_edge
    ADD CONSTRAINT group_edge_pkey PRIMARY KEY (source_id, state, "position");


--
-- Name: group_edge group_edge_source_id_destination_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_edge
    ADD CONSTRAINT group_edge_source_id_destination_id_key UNIQUE (source_id, destination_id);


--
-- Name: groups groups_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_id_key UNIQUE (id);


--
-- Name: groups groups_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_name_key UNIQUE (name);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (disable_time, lang_tag, edge_count, id);


--
-- Name: leaderboard leaderboard_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leaderboard
    ADD CONSTRAINT leaderboard_pkey PRIMARY KEY (id);


--
-- Name: leaderboard_record leaderboard_record_owner_id_leaderboard_id_expiry_time_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leaderboard_record
    ADD CONSTRAINT leaderboard_record_owner_id_leaderboard_id_expiry_time_key UNIQUE (owner_id, leaderboard_id, expiry_time);


--
-- Name: leaderboard_record leaderboard_record_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leaderboard_record
    ADD CONSTRAINT leaderboard_record_pkey PRIMARY KEY (leaderboard_id, expiry_time, score, subscore, owner_id);


--
-- Name: message message_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_id_key UNIQUE (id);


--
-- Name: message message_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_pkey PRIMARY KEY (stream_mode, stream_subject, stream_descriptor, stream_label, create_time, id);


--
-- Name: message message_sender_id_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_sender_id_id_key UNIQUE (sender_id, id);


--
-- Name: migration_info migration_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migration_info
    ADD CONSTRAINT migration_info_pkey PRIMARY KEY (id);


--
-- Name: notification notification_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_id_key UNIQUE (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (user_id, create_time, id);


--
-- Name: purchase purchase_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase
    ADD CONSTRAINT purchase_pkey PRIMARY KEY (transaction_id);


--
-- Name: storage storage_collection_key_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage
    ADD CONSTRAINT storage_collection_key_user_id_key UNIQUE (collection, key, user_id);


--
-- Name: storage storage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage
    ADD CONSTRAINT storage_pkey PRIMARY KEY (collection, read, key, user_id);


--
-- Name: user_device user_device_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_device
    ADD CONSTRAINT user_device_pkey PRIMARY KEY (id);


--
-- Name: user_device user_device_user_id_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_device
    ADD CONSTRAINT user_device_user_id_id_key UNIQUE (user_id, id);


--
-- Name: user_edge user_edge_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_edge
    ADD CONSTRAINT user_edge_pkey PRIMARY KEY (source_id, state, "position");


--
-- Name: user_edge user_edge_source_id_destination_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_edge
    ADD CONSTRAINT user_edge_source_id_destination_id_key UNIQUE (source_id, destination_id);


--
-- Name: user_tombstone user_tombstone_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_tombstone
    ADD CONSTRAINT user_tombstone_pkey PRIMARY KEY (create_time, user_id);


--
-- Name: user_tombstone user_tombstone_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_tombstone
    ADD CONSTRAINT user_tombstone_user_id_key UNIQUE (user_id);


--
-- Name: users users_apple_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_apple_id_key UNIQUE (apple_id);


--
-- Name: users users_custom_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_custom_id_key UNIQUE (custom_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_facebook_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_facebook_id_key UNIQUE (facebook_id);


--
-- Name: users users_facebook_instant_game_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_facebook_instant_game_id_key UNIQUE (facebook_instant_game_id);


--
-- Name: users users_gamecenter_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_gamecenter_id_key UNIQUE (gamecenter_id);


--
-- Name: users users_google_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_google_id_key UNIQUE (google_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_steam_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_steam_id_key UNIQUE (steam_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: wallet_ledger wallet_ledger_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_ledger
    ADD CONSTRAINT wallet_ledger_id_key UNIQUE (id);


--
-- Name: wallet_ledger wallet_ledger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_ledger
    ADD CONSTRAINT wallet_ledger_pkey PRIMARY KEY (user_id, create_time, id);


--
-- Name: collection_read_user_id_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX collection_read_user_id_key_idx ON public.storage USING btree (collection, read, user_id, key);


--
-- Name: collection_user_id_read_key_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX collection_user_id_read_key_idx ON public.storage USING btree (collection, user_id, read, key);


--
-- Name: duration_start_time_end_time_category_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX duration_start_time_end_time_category_idx ON public.leaderboard USING btree (duration, start_time, end_time DESC, category);


--
-- Name: edge_count_update_time_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX edge_count_update_time_id_idx ON public.groups USING btree (disable_time, edge_count, update_time, id);


--
-- Name: owner_id_expiry_time_leaderboard_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX owner_id_expiry_time_leaderboard_id_idx ON public.leaderboard_record USING btree (owner_id, expiry_time, leaderboard_id);


--
-- Name: purchase_user_id_purchase_time_transaction_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX purchase_user_id_purchase_time_transaction_id_idx ON public.purchase USING btree (user_id, purchase_time DESC, transaction_id);


--
-- Name: storage_auto_index_fk_user_id_ref_users; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX storage_auto_index_fk_user_id_ref_users ON public.storage USING btree (user_id);


--
-- Name: update_time_edge_count_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX update_time_edge_count_id_idx ON public.groups USING btree (disable_time, update_time, edge_count, id);


--
-- Name: user_edge_auto_index_fk_destination_id_ref_users; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX user_edge_auto_index_fk_destination_id_ref_users ON public.user_edge USING btree (destination_id);


--
-- Name: leaderboard_record leaderboard_record_leaderboard_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.leaderboard_record
    ADD CONSTRAINT leaderboard_record_leaderboard_id_fkey FOREIGN KEY (leaderboard_id) REFERENCES public.leaderboard(id) ON DELETE CASCADE;


--
-- Name: message message_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notification notification_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: purchase purchase_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.purchase
    ADD CONSTRAINT purchase_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: storage storage_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage
    ADD CONSTRAINT storage_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_device user_device_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_device
    ADD CONSTRAINT user_device_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_edge user_edge_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_edge
    ADD CONSTRAINT user_edge_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_edge user_edge_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_edge
    ADD CONSTRAINT user_edge_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: wallet_ledger wallet_ledger_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wallet_ledger
    ADD CONSTRAINT wallet_ledger_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

