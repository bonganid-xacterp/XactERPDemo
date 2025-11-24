--
-- PostgreSQL database cluster dump
--

-- Started on 2025-11-22 09:17:52

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;

--
-- User Configurations
--








--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

-- Started on 2025-11-22 09:17:52

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Completed on 2025-11-22 09:17:53

--
-- PostgreSQL database dump complete
--

--
-- Database "demoappdb" dump
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

-- Started on 2025-11-22 09:17:53

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5969 (class 1262 OID 35829)
-- Name: demoappdb; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE demoappdb WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en-US';


ALTER DATABASE demoappdb OWNER TO postgres;

\connect demoappdb

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 238 (class 1259 OID 36040)
-- Name: cl01_mast_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cl01_mast_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cl01_mast_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 239 (class 1259 OID 36041)
-- Name: cl01_mast; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cl01_mast (
    id bigint DEFAULT nextval('public.cl01_mast_id_seq'::regclass) NOT NULL,
    supp_name character varying(120) NOT NULL,
    phone character varying(11),
    email character varying(120),
    address1 character varying(100),
    address2 character varying(100),
    address3 character varying(100),
    postal_code character varying(10),
    vat_no character varying(20),
    payment_terms character varying(50),
    balance numeric(15,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint
);


ALTER TABLE public.cl01_mast OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 36096)
-- Name: cl30_trans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cl30_trans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cl30_trans_id_seq OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 36097)
-- Name: cl30_trans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cl30_trans (
    id bigint DEFAULT nextval('public.cl30_trans_id_seq'::regclass) NOT NULL,
    supp_id bigint,
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    doc_no numeric(10,0),
    doc_type character varying(20),
    gross_tot numeric(15,2) DEFAULT 0 NOT NULL,
    disc_tot numeric(15,2) DEFAULT 0 NOT NULL,
    vat_tot numeric(15,2) DEFAULT 0 NOT NULL,
    net_tot numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200)
);


ALTER TABLE public.cl30_trans OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 36115)
-- Name: cl40_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cl40_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cl40_hist_id_seq OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 36116)
-- Name: cl40_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cl40_hist (
    id bigint DEFAULT nextval('public.cl40_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.cl40_hist OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 36020)
-- Name: dl01_mast_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dl01_mast_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dl01_mast_id_seq OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 36021)
-- Name: dl01_mast; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dl01_mast (
    id bigint DEFAULT nextval('public.dl01_mast_id_seq'::regclass) NOT NULL,
    cust_name character varying(120) NOT NULL,
    phone character varying(11),
    email character varying(120),
    address1 character varying(100),
    address2 character varying(100),
    address3 character varying(100),
    postal_code character varying(10),
    vat_no character varying(20),
    payment_terms character varying(50),
    balance numeric(15,2) DEFAULT 0 NOT NULL,
    cr_limit numeric(15,2) DEFAULT 0 NOT NULL,
    sales_ytd numeric(15,2) DEFAULT 0,
    cost_ytd numeric(15,2) DEFAULT 0,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint
);


ALTER TABLE public.dl01_mast OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 36057)
-- Name: dl30_trans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dl30_trans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dl30_trans_id_seq OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 36058)
-- Name: dl30_trans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dl30_trans (
    id bigint DEFAULT nextval('public.dl30_trans_id_seq'::regclass) NOT NULL,
    cust_id bigint,
    doc_no numeric(10,0),
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    doc_type character varying(20),
    gross_tot numeric(15,2) DEFAULT 0 NOT NULL,
    vat numeric(15,2) DEFAULT 0 NOT NULL,
    disc numeric(15,2) DEFAULT 0 NOT NULL,
    net_tot numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200)
);


ALTER TABLE public.dl30_trans OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 36076)
-- Name: dl40_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dl40_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dl40_hist_id_seq OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 36077)
-- Name: dl40_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dl40_hist (
    id bigint DEFAULT nextval('public.dl40_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.dl40_hist OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 36342)
-- Name: gl01_acc_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gl01_acc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gl01_acc_id_seq OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 36343)
-- Name: gl01_acc; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gl01_acc (
    id bigint DEFAULT nextval('public.gl01_acc_id_seq'::regclass) NOT NULL,
    acc_code character varying(30),
    acc_name character varying(120) NOT NULL,
    acc_type character varying(20) NOT NULL,
    is_parent boolean DEFAULT false NOT NULL,
    parent_id bigint,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint
);


ALTER TABLE public.gl01_acc OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 36364)
-- Name: gl30_jnls_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gl30_jnls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gl30_jnls_id_seq OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 36365)
-- Name: gl30_jnls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gl30_jnls (
    id bigint DEFAULT nextval('public.gl30_jnls_id_seq'::regclass) NOT NULL,
    jrn_no character varying(30),
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    ref_no character varying(30),
    doc_type character varying(20),
    doc_no character varying(30),
    description character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint
);


ALTER TABLE public.gl30_jnls OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 36381)
-- Name: gl31_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gl31_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gl31_lines_id_seq OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 36382)
-- Name: gl31_lines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gl31_lines (
    id bigint DEFAULT nextval('public.gl31_lines_id_seq'::regclass) NOT NULL,
    jrn_id bigint NOT NULL,
    line_no integer NOT NULL,
    acc_id bigint NOT NULL,
    debit numeric(15,2) DEFAULT 0 NOT NULL,
    credit numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200)
);


ALTER TABLE public.gl31_lines OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 36402)
-- Name: gl40_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gl40_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gl40_hist_id_seq OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 36403)
-- Name: gl40_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gl40_hist (
    id bigint DEFAULT nextval('public.gl40_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.gl40_hist OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 36422)
-- Name: payt30_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payt30_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payt30_hdr_id_seq OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 36423)
-- Name: payt30_hdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payt30_hdr (
    id bigint DEFAULT nextval('public.payt30_hdr_id_seq'::regclass) NOT NULL,
    doc_no character varying(30),
    party_type character varying(10),
    party_id bigint,
    pay_type character varying(20),
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    method character varying(30),
    bank_account character varying(40),
    amount numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE public.payt30_hdr OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 36442)
-- Name: payt31_trans_det_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payt31_trans_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payt31_trans_det_id_seq OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 36443)
-- Name: payt31_trans_det; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payt31_trans_det (
    id bigint DEFAULT nextval('public.payt31_trans_det_id_seq'::regclass) NOT NULL,
    hdr_id bigint NOT NULL,
    doc_type character varying(20),
    doc_no character varying(30),
    alloc_amt numeric(15,2) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.payt31_trans_det OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 36456)
-- Name: payt40_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payt40_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payt40_hist_id_seq OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 36457)
-- Name: payt40_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payt40_hist (
    id bigint DEFAULT nextval('public.payt40_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.payt40_hist OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 36509)
-- Name: pu30_ord_det_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pu30_ord_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pu30_ord_det_id_seq OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 36510)
-- Name: pu30_ord_det; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pu30_ord_det (
    id bigint DEFAULT nextval('public.pu30_ord_det_id_seq'::regclass) NOT NULL,
    hdr_id bigint NOT NULL,
    line_no integer NOT NULL,
    stock_id bigint,
    item_name character varying(200),
    uom character varying(20),
    qnty numeric(15,3) DEFAULT 0 NOT NULL,
    unit_cost numeric(15,4) DEFAULT 0 NOT NULL,
    disc_pct numeric(7,3) DEFAULT 0 NOT NULL,
    disc_amt numeric(15,2) DEFAULT 0 NOT NULL,
    gross_amt numeric(15,2) DEFAULT 0 NOT NULL,
    vat_rate numeric(7,3) DEFAULT 0 NOT NULL,
    vat_amt numeric(15,2) DEFAULT 0 NOT NULL,
    net_excl_amt numeric(15,2) DEFAULT 0 NOT NULL,
    line_total numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    updated_at timestamp without time zone,
    updated_by bigint
);


ALTER TABLE public.pu30_ord_det OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 36476)
-- Name: pu30_ord_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pu30_ord_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pu30_ord_hdr_id_seq OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 36477)
-- Name: pu30_ord_hdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pu30_ord_hdr (
    id bigint DEFAULT nextval('public.pu30_ord_hdr_id_seq'::regclass) NOT NULL,
    doc_no character varying(30),
    ref_no character varying(30),
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    supp_id bigint,
    supp_name character varying(100),
    supp_phone character varying(20),
    supp_email character varying(100),
    supp_address1 character varying(100),
    supp_address2 character varying(100),
    supp_address3 character varying(100),
    supp_postal_code character varying(10),
    supp_vat_no character varying(20),
    supp_payment_terms character varying(50),
    gross_tot numeric(15,2) DEFAULT 0 NOT NULL,
    disc_tot numeric(15,2) DEFAULT 0 NOT NULL,
    vat_tot numeric(15,2) DEFAULT 0 NOT NULL,
    net_tot numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint,
    updated_by bigint
);


ALTER TABLE public.pu30_ord_hdr OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 36561)
-- Name: pu30_ord_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pu30_ord_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pu30_ord_hist_id_seq OWNER TO postgres;

--
-- TOC entry 284 (class 1259 OID 36562)
-- Name: pu30_ord_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pu30_ord_hist (
    id bigint DEFAULT nextval('public.pu30_ord_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.pu30_ord_hist OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 36618)
-- Name: pu31_grn_det_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pu31_grn_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pu31_grn_det_id_seq OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 36619)
-- Name: pu31_grn_det; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pu31_grn_det (
    id bigint DEFAULT nextval('public.pu31_grn_det_id_seq'::regclass) NOT NULL,
    hdr_id bigint NOT NULL,
    line_no integer NOT NULL,
    stock_id bigint,
    item_name character varying(200),
    uom character varying(20),
    batch_id character varying(40),
    expiry_date date,
    qnty numeric(15,3) DEFAULT 0 NOT NULL,
    unit_cost numeric(15,4) DEFAULT 0 NOT NULL,
    disc_pct numeric(7,3) DEFAULT 0 NOT NULL,
    disc_amt numeric(15,2) DEFAULT 0 NOT NULL,
    gross_amt numeric(15,2) DEFAULT 0 NOT NULL,
    vat_rate numeric(7,3) DEFAULT 0 NOT NULL,
    vat_amt numeric(15,2) DEFAULT 0 NOT NULL,
    net_excl_amt numeric(15,2) DEFAULT 0 NOT NULL,
    line_total numeric(15,2) DEFAULT 0 NOT NULL,
    po_line_id bigint,
    wh_id bigint,
    wb_id bigint,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    updated_at timestamp without time zone,
    updated_by bigint
);


ALTER TABLE public.pu31_grn_det OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 36581)
-- Name: pu31_grn_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pu31_grn_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pu31_grn_hdr_id_seq OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 36582)
-- Name: pu31_grn_hdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pu31_grn_hdr (
    id bigint DEFAULT nextval('public.pu31_grn_hdr_id_seq'::regclass) NOT NULL,
    doc_no numeric(10,0),
    ref_doc_type character varying(20),
    ref_doc_no bigint,
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    supp_id bigint,
    supp_name character varying(100),
    supp_phone character varying(11),
    supp_email character varying(100),
    supp_address1 character varying(100),
    supp_address2 character varying(100),
    supp_address3 character varying(100),
    supp_postal_code character varying(10),
    supp_vat_no character varying(20),
    supp_payment_terms character varying(50),
    delivery_note_no character varying(50),
    carrier_name character varying(50),
    received_by bigint,
    gross_tot numeric(15,2) DEFAULT 0 NOT NULL,
    vat_tot numeric(15,2) DEFAULT 0 NOT NULL,
    net_tot numeric(15,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint,
    updated_by bigint
);


ALTER TABLE public.pu31_grn_hdr OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 36670)
-- Name: pu31_grn_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pu31_grn_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pu31_grn_hist_id_seq OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 36671)
-- Name: pu31_grn_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pu31_grn_hist (
    id bigint DEFAULT nextval('public.pu31_grn_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.pu31_grn_hist OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 36723)
-- Name: pu32_inv_det_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pu32_inv_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pu32_inv_det_id_seq OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 36724)
-- Name: pu32_inv_det; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pu32_inv_det (
    id bigint DEFAULT nextval('public.pu32_inv_det_id_seq'::regclass) NOT NULL,
    hdr_id bigint NOT NULL,
    line_no integer NOT NULL,
    stock_id bigint,
    item_name character varying(200),
    uom character varying(20),
    batch_id character varying(40),
    expiry_date date,
    qnty numeric(15,3) DEFAULT 0 NOT NULL,
    unit_cost numeric(15,4) DEFAULT 0 NOT NULL,
    disc_pct numeric(7,3) DEFAULT 0 NOT NULL,
    disc_amt numeric(15,2) DEFAULT 0 NOT NULL,
    gross_amt numeric(15,2) DEFAULT 0 NOT NULL,
    vat_rate numeric(7,3) DEFAULT 0 NOT NULL,
    vat_amt numeric(15,2) DEFAULT 0 NOT NULL,
    net_excl_amt numeric(15,2) DEFAULT 0 NOT NULL,
    line_total numeric(15,2) DEFAULT 0 NOT NULL,
    wh_id bigint,
    wb_id bigint,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    updated_at timestamp without time zone,
    updated_by bigint
);


ALTER TABLE public.pu32_inv_det OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 36690)
-- Name: pu32_inv_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pu32_inv_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pu32_inv_hdr_id_seq OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 36691)
-- Name: pu32_inv_hdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pu32_inv_hdr (
    id bigint DEFAULT nextval('public.pu32_inv_hdr_id_seq'::regclass) NOT NULL,
    doc_no character varying(30),
    ref_doc_type character varying(20),
    ref_doc_no character varying(30),
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    invoice_date date,
    due_date date,
    payment_method character varying(30),
    supp_id bigint,
    supp_name character varying(100),
    supp_phone character varying(20),
    supp_email character varying(100),
    supp_address1 character varying(100),
    supp_address2 character varying(100),
    supp_address3 character varying(100),
    supp_postal_code character varying(10),
    supp_vat_no character varying(20),
    supp_payment_terms character varying(50),
    supp_bank_name character varying(60),
    supp_bank_account character varying(40),
    supp_bank_branch character varying(40),
    gross_tot numeric(15,2) DEFAULT 0 NOT NULL,
    disc_tot numeric(15,2) DEFAULT 0 NOT NULL,
    vat_tot numeric(15,2) DEFAULT 0 NOT NULL,
    net_tot numeric(15,2) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint,
    updated_by bigint
);


ALTER TABLE public.pu32_inv_hdr OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 36775)
-- Name: pu32_inv_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pu32_inv_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pu32_inv_hist_id_seq OWNER TO postgres;

--
-- TOC entry 296 (class 1259 OID 36776)
-- Name: pu32_inv_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pu32_inv_hist (
    id bigint DEFAULT nextval('public.pu32_inv_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.pu32_inv_hist OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 36828)
-- Name: sa30_quo_det_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa30_quo_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa30_quo_det_id_seq OWNER TO postgres;

--
-- TOC entry 300 (class 1259 OID 36829)
-- Name: sa30_quo_det; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa30_quo_det (
    id bigint DEFAULT nextval('public.sa30_quo_det_id_seq'::regclass) NOT NULL,
    hdr_id bigint NOT NULL,
    line_no integer NOT NULL,
    stock_id bigint,
    item_name character varying(200),
    uom character varying(20),
    qnty numeric(15,3) DEFAULT 0 NOT NULL,
    unit_price numeric(15,4) DEFAULT 0 NOT NULL,
    disc_pct numeric(7,3) DEFAULT 0 NOT NULL,
    disc_amt numeric(15,2) DEFAULT 0 NOT NULL,
    gross_amt numeric(15,2) DEFAULT 0 NOT NULL,
    vat_rate numeric(7,3) DEFAULT 0 NOT NULL,
    vat_amt numeric(15,2) DEFAULT 0 NOT NULL,
    net_excl_amt numeric(15,2) DEFAULT 0 NOT NULL,
    line_total numeric(15,2) DEFAULT 0 NOT NULL,
    wh_id bigint,
    wb_id bigint,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    updated_at timestamp without time zone,
    updated_by bigint
);


ALTER TABLE public.sa30_quo_det OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 36795)
-- Name: sa30_quo_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa30_quo_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa30_quo_hdr_id_seq OWNER TO postgres;

--
-- TOC entry 298 (class 1259 OID 36796)
-- Name: sa30_quo_hdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa30_quo_hdr (
    id bigint DEFAULT nextval('public.sa30_quo_hdr_id_seq'::regclass) NOT NULL,
    doc_no character varying(30),
    ref_no character varying(30),
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    cust_id bigint,
    cust_name character varying(100),
    cust_phone character varying(20),
    cust_email character varying(100),
    cust_address1 character varying(100),
    cust_address2 character varying(100),
    cust_address3 character varying(100),
    cust_postal_code character varying(10),
    cust_vat_no character varying(20),
    cust_payment_terms character varying(50),
    gross_tot numeric(15,2) DEFAULT 0 NOT NULL,
    disc_tot numeric(15,2) DEFAULT 0 NOT NULL,
    vat_tot numeric(15,2) DEFAULT 0 NOT NULL,
    net_tot numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint,
    updated_by bigint
);


ALTER TABLE public.sa30_quo_hdr OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 36880)
-- Name: sa30_quo_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa30_quo_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa30_quo_hist_id_seq OWNER TO postgres;

--
-- TOC entry 302 (class 1259 OID 36881)
-- Name: sa30_quo_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa30_quo_hist (
    id bigint DEFAULT nextval('public.sa30_quo_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.sa30_quo_hist OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 36933)
-- Name: sa31_ord_det_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa31_ord_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa31_ord_det_id_seq OWNER TO postgres;

--
-- TOC entry 306 (class 1259 OID 36934)
-- Name: sa31_ord_det; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa31_ord_det (
    id bigint DEFAULT nextval('public.sa31_ord_det_id_seq'::regclass) NOT NULL,
    hdr_id bigint NOT NULL,
    line_no integer NOT NULL,
    stock_id bigint,
    item_name character varying(200),
    uom character varying(20),
    qnty numeric(15,3) DEFAULT 0 NOT NULL,
    unit_price numeric(15,4) DEFAULT 0 NOT NULL,
    disc_pct numeric(7,3) DEFAULT 0 NOT NULL,
    disc_amt numeric(15,2) DEFAULT 0 NOT NULL,
    gross_amt numeric(15,2) DEFAULT 0 NOT NULL,
    vat_rate numeric(7,3) DEFAULT 0 NOT NULL,
    vat_amt numeric(15,2) DEFAULT 0 NOT NULL,
    net_excl_amt numeric(15,2) DEFAULT 0 NOT NULL,
    line_total numeric(15,2) DEFAULT 0 NOT NULL,
    wh_id bigint,
    wb_id bigint,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    updated_at timestamp without time zone,
    updated_by bigint
);


ALTER TABLE public.sa31_ord_det OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 36900)
-- Name: sa31_ord_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa31_ord_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa31_ord_hdr_id_seq OWNER TO postgres;

--
-- TOC entry 304 (class 1259 OID 36901)
-- Name: sa31_ord_hdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa31_ord_hdr (
    id bigint DEFAULT nextval('public.sa31_ord_hdr_id_seq'::regclass) NOT NULL,
    doc_no character varying(30),
    ref_doc_type character varying(20),
    ref_doc_no character varying(30),
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    cust_id bigint,
    cust_name character varying(100),
    cust_phone character varying(20),
    cust_email character varying(100),
    cust_address1 character varying(100),
    cust_address2 character varying(100),
    cust_address3 character varying(100),
    cust_postal_code character varying(10),
    cust_vat_no character varying(20),
    cust_payment_terms character varying(50),
    gross_tot numeric(15,2) DEFAULT 0 NOT NULL,
    disc_tot numeric(15,2) DEFAULT 0 NOT NULL,
    vat_tot numeric(15,2) DEFAULT 0 NOT NULL,
    net_tot numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint,
    updated_by bigint
);


ALTER TABLE public.sa31_ord_hdr OWNER TO postgres;

--
-- TOC entry 307 (class 1259 OID 36985)
-- Name: sa31_ord_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa31_ord_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa31_ord_hist_id_seq OWNER TO postgres;

--
-- TOC entry 308 (class 1259 OID 36986)
-- Name: sa31_ord_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa31_ord_hist (
    id bigint DEFAULT nextval('public.sa31_ord_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.sa31_ord_hist OWNER TO postgres;

--
-- TOC entry 311 (class 1259 OID 37038)
-- Name: sa32_inv_det_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa32_inv_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa32_inv_det_id_seq OWNER TO postgres;

--
-- TOC entry 312 (class 1259 OID 37039)
-- Name: sa32_inv_det; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa32_inv_det (
    id bigint DEFAULT nextval('public.sa32_inv_det_id_seq'::regclass) NOT NULL,
    hdr_id bigint NOT NULL,
    line_no integer NOT NULL,
    stock_id bigint,
    item_name character varying(200),
    uom character varying(20),
    qnty numeric(15,3) DEFAULT 0 NOT NULL,
    unit_price numeric(15,4) DEFAULT 0 NOT NULL,
    disc_pct numeric(7,3) DEFAULT 0 NOT NULL,
    disc_amt numeric(15,2) DEFAULT 0 NOT NULL,
    gross_amt numeric(15,2) DEFAULT 0 NOT NULL,
    vat_rate numeric(7,3) DEFAULT 0 NOT NULL,
    vat_amt numeric(15,2) DEFAULT 0 NOT NULL,
    net_excl_amt numeric(15,2) DEFAULT 0 NOT NULL,
    line_total numeric(15,2) DEFAULT 0 NOT NULL,
    wh_id bigint,
    wb_id bigint,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    updated_at timestamp without time zone,
    updated_by bigint
);


ALTER TABLE public.sa32_inv_det OWNER TO postgres;

--
-- TOC entry 309 (class 1259 OID 37005)
-- Name: sa32_inv_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa32_inv_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa32_inv_hdr_id_seq OWNER TO postgres;

--
-- TOC entry 310 (class 1259 OID 37006)
-- Name: sa32_inv_hdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa32_inv_hdr (
    id bigint DEFAULT nextval('public.sa32_inv_hdr_id_seq'::regclass) NOT NULL,
    doc_no character varying(30),
    ref_doc_type character varying(20),
    ref_doc_no character varying(30),
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    due_date date,
    cust_id bigint,
    cust_name character varying(100),
    cust_phone character varying(20),
    cust_email character varying(100),
    cust_address1 character varying(100),
    cust_address2 character varying(100),
    cust_address3 character varying(100),
    cust_postal_code character varying(10),
    cust_vat_no character varying(20),
    cust_payment_terms character varying(50),
    gross_tot numeric(15,2) DEFAULT 0 NOT NULL,
    disc_tot numeric(15,2) DEFAULT 0 NOT NULL,
    vat_tot numeric(15,2) DEFAULT 0 NOT NULL,
    net_tot numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint,
    updated_by bigint
);


ALTER TABLE public.sa32_inv_hdr OWNER TO postgres;

--
-- TOC entry 313 (class 1259 OID 37090)
-- Name: sa32_inv_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa32_inv_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa32_inv_hist_id_seq OWNER TO postgres;

--
-- TOC entry 314 (class 1259 OID 37091)
-- Name: sa32_inv_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa32_inv_hist (
    id bigint DEFAULT nextval('public.sa32_inv_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.sa32_inv_hist OWNER TO postgres;

--
-- TOC entry 317 (class 1259 OID 37143)
-- Name: sa33_crn_det_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa33_crn_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa33_crn_det_id_seq OWNER TO postgres;

--
-- TOC entry 318 (class 1259 OID 37144)
-- Name: sa33_crn_det; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa33_crn_det (
    id bigint DEFAULT nextval('public.sa33_crn_det_id_seq'::regclass) NOT NULL,
    hdr_id bigint NOT NULL,
    line_no integer NOT NULL,
    stock_id bigint,
    item_name character varying(200),
    uom character varying(20),
    qnty numeric(15,3) DEFAULT 0 NOT NULL,
    unit_price numeric(15,4) DEFAULT 0 NOT NULL,
    disc_pct numeric(7,3) DEFAULT 0 NOT NULL,
    disc_amt numeric(15,2) DEFAULT 0 NOT NULL,
    gross_amt numeric(15,2) DEFAULT 0 NOT NULL,
    vat_rate numeric(7,3) DEFAULT 0 NOT NULL,
    vat_amt numeric(15,2) DEFAULT 0 NOT NULL,
    net_amt numeric(15,2) DEFAULT 0 NOT NULL,
    line_total numeric(15,2) DEFAULT 0 NOT NULL,
    wh_id bigint,
    wb_id bigint,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    updated_at timestamp without time zone,
    updated_by bigint
);


ALTER TABLE public.sa33_crn_det OWNER TO postgres;

--
-- TOC entry 315 (class 1259 OID 37110)
-- Name: sa33_crn_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa33_crn_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa33_crn_hdr_id_seq OWNER TO postgres;

--
-- TOC entry 316 (class 1259 OID 37111)
-- Name: sa33_crn_hdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa33_crn_hdr (
    id bigint DEFAULT nextval('public.sa33_crn_hdr_id_seq'::regclass) NOT NULL,
    doc_no character varying(30),
    ref_doc_type character varying(20),
    ref_doc_no character varying(30),
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    credit_date date,
    cust_id bigint,
    cust_name character varying(100),
    cust_phone character varying(20),
    cust_email character varying(100),
    cust_address1 character varying(100),
    cust_address2 character varying(100),
    cust_address3 character varying(100),
    cust_postal_code character varying(10),
    cust_vat_no character varying(20),
    cust_payment_terms character varying(50),
    gross_tot numeric(15,2) DEFAULT 0 NOT NULL,
    disc_tot numeric(15,2) DEFAULT 0 NOT NULL,
    vat_tot numeric(15,2) DEFAULT 0 NOT NULL,
    net_tot numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint,
    updated_by bigint
);


ALTER TABLE public.sa33_crn_hdr OWNER TO postgres;

--
-- TOC entry 319 (class 1259 OID 37195)
-- Name: sa33_crn_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sa33_crn_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sa33_crn_hist_id_seq OWNER TO postgres;

--
-- TOC entry 320 (class 1259 OID 37196)
-- Name: sa33_crn_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sa33_crn_hist (
    id bigint DEFAULT nextval('public.sa33_crn_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.sa33_crn_hist OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 36188)
-- Name: st01_mast_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.st01_mast_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.st01_mast_id_seq OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 36189)
-- Name: st01_mast; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.st01_mast (
    id bigint DEFAULT nextval('public.st01_mast_id_seq'::regclass) NOT NULL,
    stock_code character varying(30),
    description character varying(200) NOT NULL,
    barcode character varying(60),
    batch_control boolean DEFAULT false,
    has_expiry_date boolean DEFAULT false,
    category_id bigint NOT NULL,
    unit_cost numeric(15,4) DEFAULT 0 NOT NULL,
    sell_price numeric(15,4) DEFAULT 0 NOT NULL,
    stock_on_hand numeric(15,3) DEFAULT 0 NOT NULL,
    total_purch numeric(15,3) DEFAULT 0 NOT NULL,
    total_sales numeric(15,3) DEFAULT 0 NOT NULL,
    reserved_qnty numeric(15,3) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint NOT NULL,
    uom character varying(20),
    stock_balance numeric(5,3),
    stock_ordered numeric(5,3)
);


ALTER TABLE public.st01_mast OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 36172)
-- Name: st02_cat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.st02_cat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.st02_cat_id_seq OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 36173)
-- Name: st02_cat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.st02_cat (
    id bigint DEFAULT nextval('public.st02_cat_id_seq'::regclass) NOT NULL,
    cat_code character varying(30),
    cat_name character varying(120) NOT NULL,
    description character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint
);


ALTER TABLE public.st02_cat OWNER TO postgres;

--
-- TOC entry 332 (class 1259 OID 37848)
-- Name: st03_uom_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.st03_uom_master (
    id bigint NOT NULL,
    uom_code character varying(20) NOT NULL,
    uom_name character varying(50) NOT NULL,
    uom_type character varying(20) DEFAULT 'UNIT'::character varying,
    status character varying(10) DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.st03_uom_master OWNER TO postgres;

--
-- TOC entry 331 (class 1259 OID 37847)
-- Name: st03_uom_master_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.st03_uom_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.st03_uom_master_id_seq OWNER TO postgres;

--
-- TOC entry 5970 (class 0 OID 0)
-- Dependencies: 331
-- Name: st03_uom_master_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.st03_uom_master_id_seq OWNED BY public.st03_uom_master.id;


--
-- TOC entry 334 (class 1259 OID 37918)
-- Name: st04_stock_uom; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.st04_stock_uom (
    id bigint NOT NULL,
    stock_id bigint NOT NULL,
    uom_id bigint NOT NULL,
    is_base_uom boolean DEFAULT false,
    conversion_factor numeric(15,6) DEFAULT 1,
    barcode character varying(60),
    unit_cost numeric(15,4),
    sell_price numeric(15,4),
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.st04_stock_uom OWNER TO postgres;

--
-- TOC entry 333 (class 1259 OID 37917)
-- Name: st04_stock_uom_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.st04_stock_uom_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.st04_stock_uom_id_seq OWNER TO postgres;

--
-- TOC entry 5971 (class 0 OID 0)
-- Dependencies: 333
-- Name: st04_stock_uom_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.st04_stock_uom_id_seq OWNED BY public.st04_stock_uom.id;


--
-- TOC entry 336 (class 1259 OID 37970)
-- Name: st30_trans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.st30_trans (
    id bigint NOT NULL,
    stock_id bigint NOT NULL,
    trans_date date NOT NULL,
    doc_type character varying(10) NOT NULL,
    direction character varying(3) NOT NULL,
    qnty numeric(12,2) NOT NULL,
    unit_cost numeric(12,2) DEFAULT 0,
    sell_price numeric(12,2) DEFAULT 0,
    batch_id character varying(30),
    expiry_date date,
    notes character varying(200)
);


ALTER TABLE public.st30_trans OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 36217)
-- Name: st30_trans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.st30_trans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.st30_trans_id_seq OWNER TO postgres;

--
-- TOC entry 335 (class 1259 OID 37969)
-- Name: st30_trans_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.st30_trans_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.st30_trans_id_seq1 OWNER TO postgres;

--
-- TOC entry 5972 (class 0 OID 0)
-- Dependencies: 335
-- Name: st30_trans_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.st30_trans_id_seq1 OWNED BY public.st30_trans.id;


--
-- TOC entry 257 (class 1259 OID 36256)
-- Name: st40_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.st40_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.st40_hist_id_seq OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 36257)
-- Name: st40_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.st40_hist (
    id bigint DEFAULT nextval('public.st40_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.st40_hist OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 35916)
-- Name: sy00_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy00_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy00_user_id_seq OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 35917)
-- Name: sy00_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sy00_user (
    id bigint DEFAULT nextval('public.sy00_user_id_seq'::regclass) NOT NULL,
    username character varying(60) NOT NULL,
    full_name character varying(120),
    phone character varying(30),
    email character varying(120),
    password character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    role_id bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE public.sy00_user OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 35934)
-- Name: sy01_sess_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy01_sess_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy01_sess_id_seq OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 35935)
-- Name: sy01_sess; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sy01_sess (
    id bigint DEFAULT nextval('public.sy01_sess_id_seq'::regclass) NOT NULL,
    user_id bigint NOT NULL,
    uuid character varying(64) NOT NULL,
    login_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    logout_time timestamp without time zone
);


ALTER TABLE public.sy01_sess OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 35947)
-- Name: sy02_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy02_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy02_logs_id_seq OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 35948)
-- Name: sy02_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sy02_logs (
    id bigint DEFAULT nextval('public.sy02_logs_id_seq'::regclass) NOT NULL,
    user_id bigint,
    level character varying(20),
    action character varying(120),
    details text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.sy02_logs OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 35962)
-- Name: sy03_sett_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy03_sett_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy03_sett_id_seq OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 35963)
-- Name: sy03_sett; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sy03_sett (
    id bigint DEFAULT nextval('public.sy03_sett_id_seq'::regclass) NOT NULL,
    sett_key character varying(120) NOT NULL,
    sett_value text,
    description text,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.sy03_sett OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 35875)
-- Name: sy04_role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy04_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy04_role_id_seq OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 35876)
-- Name: sy04_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sy04_role (
    id bigint DEFAULT nextval('public.sy04_role_id_seq'::regclass) NOT NULL,
    role_name character varying(60) NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE public.sy04_role OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 35886)
-- Name: sy05_perm_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy05_perm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy05_perm_id_seq OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 35887)
-- Name: sy05_perm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sy05_perm (
    id bigint DEFAULT nextval('public.sy05_perm_id_seq'::regclass) NOT NULL,
    perm_name character varying(120) NOT NULL,
    description character varying(200),
    perm_code character varying(60),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint
);


ALTER TABLE public.sy05_perm OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 35897)
-- Name: sy06_role_perm_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy06_role_perm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy06_role_perm_id_seq OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 35898)
-- Name: sy06_role_perm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sy06_role_perm (
    id bigint DEFAULT nextval('public.sy06_role_perm_id_seq'::regclass) NOT NULL,
    role_id bigint NOT NULL,
    perm_id bigint NOT NULL
);


ALTER TABLE public.sy06_role_perm OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 35974)
-- Name: sy07_doc_num_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy07_doc_num_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy07_doc_num_id_seq OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 35975)
-- Name: sy07_doc_num; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sy07_doc_num (
    id bigint DEFAULT nextval('public.sy07_doc_num_id_seq'::regclass) NOT NULL,
    doc_name character varying(60) NOT NULL,
    prefix character varying(20),
    next_no bigint DEFAULT 1 NOT NULL,
    step integer DEFAULT 1 NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_by bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.sy07_doc_num OWNER TO postgres;

--
-- TOC entry 338 (class 1259 OID 38155)
-- Name: sy08_lkup_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sy08_lkup_config (
    id bigint NOT NULL,
    lookup_code character varying(60) NOT NULL,
    table_name character varying(120) NOT NULL,
    key_field character varying(120) NOT NULL,
    desc_field character varying(120) NOT NULL,
    extra_field character varying(200),
    display_title character varying(120) NOT NULL,
    filter_condition character varying(400),
    col1_title character varying(120),
    col2_title character varying(120),
    col3_title character varying(120),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.sy08_lkup_config OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 35992)
-- Name: sy08_lkup_config_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy08_lkup_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy08_lkup_config_id_seq OWNER TO postgres;

--
-- TOC entry 337 (class 1259 OID 38154)
-- Name: sy08_lkup_config_id_seq1; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy08_lkup_config_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy08_lkup_config_id_seq1 OWNER TO postgres;

--
-- TOC entry 5973 (class 0 OID 0)
-- Dependencies: 337
-- Name: sy08_lkup_config_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sy08_lkup_config_id_seq1 OWNED BY public.sy08_lkup_config.id;


--
-- TOC entry 234 (class 1259 OID 36005)
-- Name: sy40_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sy40_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sy40_hist_id_seq OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 36006)
-- Name: sy40_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sy40_hist (
    id bigint DEFAULT nextval('public.sy40_hist_id_seq'::regclass) NOT NULL,
    entity character varying(60) NOT NULL,
    ref_id bigint,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.sy40_hist OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 36151)
-- Name: wb01_mast_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wb01_mast_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wb01_mast_id_seq OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 36152)
-- Name: wb01_mast; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wb01_mast (
    id bigint DEFAULT nextval('public.wb01_mast_id_seq'::regclass) NOT NULL,
    wb_code character varying(30),
    wh_id bigint NOT NULL,
    description character varying(120),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint
);


ALTER TABLE public.wb01_mast OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 36276)
-- Name: wb30_trf_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wb30_trf_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wb30_trf_hdr_id_seq OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 36277)
-- Name: wb30_trf_hdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wb30_trf_hdr (
    id bigint DEFAULT nextval('public.wb30_trf_hdr_id_seq'::regclass) NOT NULL,
    trans_no character varying(30),
    wb_from bigint,
    wb_to bigint,
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    created_by bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE public.wb30_trf_hdr OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 36302)
-- Name: wb31_trf_det_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wb31_trf_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wb31_trf_det_id_seq OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 36303)
-- Name: wb31_trf_det; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wb31_trf_det (
    id bigint DEFAULT nextval('public.wb31_trf_det_id_seq'::regclass) NOT NULL,
    hdr_id bigint NOT NULL,
    item_no integer NOT NULL,
    stock_id bigint,
    qnty numeric(15,3) DEFAULT 0 NOT NULL,
    batch_id character varying(40),
    expiry_date date
);


ALTER TABLE public.wb31_trf_det OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 36322)
-- Name: wb40_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wb40_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wb40_hist_id_seq OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 36323)
-- Name: wb40_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wb40_hist (
    id bigint DEFAULT nextval('public.wb40_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.wb40_hist OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 36135)
-- Name: wh01_mast_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wh01_mast_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wh01_mast_id_seq OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 36136)
-- Name: wh01_mast; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wh01_mast (
    id bigint DEFAULT nextval('public.wh01_mast_id_seq'::regclass) NOT NULL,
    wh_code character varying(30),
    wh_name character varying(120) NOT NULL,
    location character varying(120),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by bigint
);


ALTER TABLE public.wh01_mast OWNER TO postgres;

--
-- TOC entry 321 (class 1259 OID 37236)
-- Name: wh30_trans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wh30_trans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wh30_trans_id_seq OWNER TO postgres;

--
-- TOC entry 322 (class 1259 OID 37237)
-- Name: wh30_trans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wh30_trans (
    id bigint DEFAULT nextval('public.wh30_trans_id_seq'::regclass) NOT NULL,
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    trans_type character varying(20),
    ref_no character varying(40),
    source_module character varying(20),
    source_doc_id bigint,
    wh_id bigint,
    wb_id bigint,
    stock_id bigint,
    qnty_in numeric(15,3) DEFAULT 0 NOT NULL,
    qnty_out numeric(15,3) DEFAULT 0 NOT NULL,
    run_qty numeric(15,3),
    uom character varying(20),
    unit_cost numeric(15,4) DEFAULT 0 NOT NULL,
    ext_cost numeric(15,2) DEFAULT 0 NOT NULL,
    remarks character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_by bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint,
    updated_at timestamp without time zone
);


ALTER TABLE public.wh30_trans OWNER TO postgres;

--
-- TOC entry 325 (class 1259 OID 37301)
-- Name: wh30_trf_hdr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wh30_trf_hdr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wh30_trf_hdr_id_seq OWNER TO postgres;

--
-- TOC entry 326 (class 1259 OID 37302)
-- Name: wh30_trf_hdr; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wh30_trf_hdr (
    id bigint DEFAULT nextval('public.wh30_trf_hdr_id_seq'::regclass) NOT NULL,
    trans_no character varying(30),
    from_wh_id bigint NOT NULL,
    to_wh_id bigint NOT NULL,
    from_wb_id bigint,
    to_wb_id bigint,
    trans_date date DEFAULT CURRENT_DATE NOT NULL,
    notes text,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_by bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by bigint,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE public.wh30_trf_hdr OWNER TO postgres;

--
-- TOC entry 327 (class 1259 OID 37349)
-- Name: wh31_trf_det_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wh31_trf_det_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wh31_trf_det_id_seq OWNER TO postgres;

--
-- TOC entry 328 (class 1259 OID 37350)
-- Name: wh31_trf_det; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wh31_trf_det (
    id bigint DEFAULT nextval('public.wh31_trf_det_id_seq'::regclass) NOT NULL,
    hdr_id bigint NOT NULL,
    item_no integer NOT NULL,
    stock_id bigint,
    item_name character varying(200),
    uom character varying(20),
    from_wb_id bigint,
    to_wb_id bigint,
    batch_id character varying(40),
    expiry_date date,
    qnty numeric(15,3) DEFAULT 0 NOT NULL,
    unit_cost numeric(15,4) DEFAULT 0 NOT NULL,
    ext_cost numeric(15,2) DEFAULT 0 NOT NULL,
    notes character varying(200),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by bigint,
    updated_at timestamp without time zone,
    updated_by bigint
);


ALTER TABLE public.wh31_trf_det OWNER TO postgres;

--
-- TOC entry 323 (class 1259 OID 37280)
-- Name: wh40_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wh40_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wh40_hist_id_seq OWNER TO postgres;

--
-- TOC entry 324 (class 1259 OID 37281)
-- Name: wh40_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wh40_hist (
    id bigint DEFAULT nextval('public.wh40_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.wh40_hist OWNER TO postgres;

--
-- TOC entry 329 (class 1259 OID 37397)
-- Name: wh40_trf_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wh40_trf_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wh40_trf_hist_id_seq OWNER TO postgres;

--
-- TOC entry 330 (class 1259 OID 37398)
-- Name: wh40_trf_hist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wh40_trf_hist (
    id bigint DEFAULT nextval('public.wh40_trf_hist_id_seq'::regclass) NOT NULL,
    ref_id bigint NOT NULL,
    action character varying(50) NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by bigint,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.wh40_trf_hist OWNER TO postgres;

--
-- TOC entry 5316 (class 2604 OID 37851)
-- Name: st03_uom_master id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st03_uom_master ALTER COLUMN id SET DEFAULT nextval('public.st03_uom_master_id_seq'::regclass);


--
-- TOC entry 5320 (class 2604 OID 37921)
-- Name: st04_stock_uom id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st04_stock_uom ALTER COLUMN id SET DEFAULT nextval('public.st04_stock_uom_id_seq'::regclass);


--
-- TOC entry 5327 (class 2604 OID 37973)
-- Name: st30_trans id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st30_trans ALTER COLUMN id SET DEFAULT nextval('public.st30_trans_id_seq1'::regclass);


--
-- TOC entry 5330 (class 2604 OID 38158)
-- Name: sy08_lkup_config id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy08_lkup_config ALTER COLUMN id SET DEFAULT nextval('public.sy08_lkup_config_id_seq1'::regclass);


--
-- TOC entry 5864 (class 0 OID 36041)
-- Dependencies: 239
-- Data for Name: cl01_mast; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cl01_mast (id, supp_name, phone, email, address1, address2, address3, postal_code, vat_no, payment_terms, balance, status, created_at, updated_at, deleted_at, created_by) FROM stdin;
2	supplier 2	0908989898	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	active	2025-11-11 13:08:06.96	\N	\N	2
3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	active	2025-11-11 13:24:36.319	\N	\N	2
1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	active	2025-11-11 10:49:51.417	\N	\N	2
4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	active	2025-11-14 09:12:06.368	2025-11-14 09:12:46.796	\N	2
5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	0.00	active	2025-11-17 05:45:37.18	2025-11-17 05:46:06.184	\N	2
6	Donny brook Spar	0125254545	info@spar.co	address 1	address 2	addres 3	4521	452112125445	\N	0.00	active	2025-11-18 08:26:39.888	2025-11-18 08:27:11.476	\N	2
7	Ushaka Fruits & Veg	0909090999	ushaka@email.com	addrees 2	address 3	address 4	45896	7854125896	0	0.00	active	2025-11-18 08:29:19.667	2025-11-18 08:30:04.658	\N	2
\.


--
-- TOC entry 5870 (class 0 OID 36097)
-- Dependencies: 245
-- Data for Name: cl30_trans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cl30_trans (id, supp_id, trans_date, doc_no, doc_type, gross_tot, disc_tot, vat_tot, net_tot, notes) FROM stdin;
5	1	2025-11-17	117	PO	0.00	0.00	0.00	0.00	\N
6	3	2025-11-17	118	PO	0.00	0.00	0.00	0.00	\N
7	5	2025-11-17	119	PO	0.00	0.00	0.00	0.00	\N
8	1	2025-11-17	120	PO	0.00	0.00	0.00	0.00	\N
9	1	2025-11-17	121	PO	85.00	0.00	12.75	97.75	\N
10	1	2025-11-17	122	PO	85.00	0.00	12.75	97.75	\N
11	3	2025-11-18	123	PO	8.50	0.00	1.28	9.78	\N
12	1	2025-11-18	124	PO	85.00	0.00	12.75	97.75	\N
13	1	2025-11-18	125	PO	85.00	0.00	12.75	97.75	\N
14	4	2025-11-18	126	PO	0.00	0.00	0.00	0.00	\N
15	1	2025-11-18	127	PO	1727.50	0.00	259.13	1986.63	\N
16	2	2025-11-18	129	PO	722.50	0.00	108.38	830.88	\N
\.


--
-- TOC entry 5872 (class 0 OID 36116)
-- Dependencies: 247
-- Data for Name: cl40_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cl40_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5862 (class 0 OID 36021)
-- Dependencies: 237
-- Data for Name: dl01_mast; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dl01_mast (id, cust_name, phone, email, address1, address2, address3, postal_code, vat_no, payment_terms, balance, cr_limit, sales_ytd, cost_ytd, status, created_at, updated_at, deleted_at, created_by) FROM stdin;
3	customer 1	01234555555	info@oli.com	sadd 1	add 3	add 2	9809	088998	30	0.00	10000.00	\N	\N	active	2025-11-11 15:03:17.2	\N	\N	2
4	bongani	99999999	info@mik.com	adda9	add9	add0	090	809090	0	0.00	780.00	\N	\N	active	2025-11-12 08:17:23.562	\N	\N	2
5	Lungile L	0123652362	info@lungile.co	add3	add4	add2	0980	898989898	0	0.00	5800.00	\N	\N	active	2025-11-18 13:51:48.101	\N	\N	2
\.


--
-- TOC entry 5866 (class 0 OID 36058)
-- Dependencies: 241
-- Data for Name: dl30_trans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dl30_trans (id, cust_id, doc_no, trans_date, doc_type, gross_tot, vat, disc, net_tot, notes) FROM stdin;
\.


--
-- TOC entry 5868 (class 0 OID 36077)
-- Dependencies: 243
-- Data for Name: dl40_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dl40_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5891 (class 0 OID 36343)
-- Dependencies: 266
-- Data for Name: gl01_acc; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gl01_acc (id, acc_code, acc_name, acc_type, is_parent, parent_id, status, created_at, updated_at, deleted_at, created_by) FROM stdin;
\.


--
-- TOC entry 5893 (class 0 OID 36365)
-- Dependencies: 268
-- Data for Name: gl30_jnls; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gl30_jnls (id, jrn_no, trans_date, ref_no, doc_type, doc_no, description, status, created_at, updated_at, deleted_at, created_by) FROM stdin;
\.


--
-- TOC entry 5895 (class 0 OID 36382)
-- Dependencies: 270
-- Data for Name: gl31_lines; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gl31_lines (id, jrn_id, line_no, acc_id, debit, credit, notes) FROM stdin;
\.


--
-- TOC entry 5897 (class 0 OID 36403)
-- Dependencies: 272
-- Data for Name: gl40_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gl40_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5899 (class 0 OID 36423)
-- Dependencies: 274
-- Data for Name: payt30_hdr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payt30_hdr (id, doc_no, party_type, party_id, pay_type, trans_date, method, bank_account, amount, notes, status, created_at, created_by, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5901 (class 0 OID 36443)
-- Dependencies: 276
-- Data for Name: payt31_trans_det; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payt31_trans_det (id, hdr_id, doc_type, doc_no, alloc_amt, created_at) FROM stdin;
\.


--
-- TOC entry 5903 (class 0 OID 36457)
-- Dependencies: 278
-- Data for Name: payt40_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payt40_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5907 (class 0 OID 36510)
-- Dependencies: 282
-- Data for Name: pu30_ord_det; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pu30_ord_det (id, hdr_id, line_no, stock_id, item_name, uom, qnty, unit_cost, disc_pct, disc_amt, gross_amt, vat_rate, vat_amt, net_excl_amt, line_total, notes, status, created_at, created_by, updated_at, updated_by) FROM stdin;
1	117	1	10	5Lt Cooking Oil	EA	15.000	8.5000	0.000	0.00	127.50	15.000	19.13	127.50	146.63	\N	active	2025-11-17 16:38:27.131	4	\N	\N
2	118	1	10	5Lt Cooking Oil	EA	500.000	8.5000	0.000	0.00	4250.00	15.000	637.50	4250.00	4887.50	\N	active	2025-11-17 16:40:04.262	4	\N	\N
3	119	1	10	5Lt Cooking Oil	EA	10.000	8.5000	15.000	12.75	85.00	15.000	10.84	72.25	83.09	\N	active	2025-11-17 16:45:22.73	4	\N	\N
4	120	1	10	5Lt Cooking Oil	EA	10.000	8.5000	0.000	0.00	85.00	15.000	12.75	85.00	97.75	\N	active	2025-11-17 16:46:12.188	4	\N	\N
5	121	1	10	5Lt Cooking Oil	EA	10.000	8.5000	0.000	0.00	85.00	15.000	12.75	85.00	97.75	\N	active	2025-11-17 16:48:57.279	4	\N	\N
6	122	1	10	5Lt Cooking Oil	EA	10.000	8.5000	0.000	0.00	85.00	15.000	12.75	85.00	97.75	\N	active	2025-11-17 16:51:16.661	4	\N	\N
7	123	1	10	5Lt Cooking Oil	EA	1.000	8.5000	0.000	0.00	8.50	15.000	1.28	8.50	9.78	\N	active	2025-11-18 07:43:43.515	4	\N	\N
9	124	1	10	5Lt Cooking Oil	EA	10.000	8.5000	0.000	0.00	85.00	15.000	12.75	85.00	97.75	\N	active	2025-11-18 08:07:39.499	3	\N	\N
10	125	1	10	5Lt Cooking Oil	EA	10.000	8.5000	0.000	0.00	85.00	15.000	12.75	85.00	97.75	\N	active	2025-11-18 08:10:17.539	4	\N	\N
11	126	1	10	5Lt Cooking Oil	EA	15.000	8.5000	0.000	0.00	127.50	15.000	19.13	127.50	146.63	\N	active	2025-11-18 08:11:59.651	3	\N	\N
15	127	1	10	5Lt Cooking Oil	EA	15.000	8.5000	0.000	0.00	127.50	15.000	19.13	127.50	146.63	\N	active	2025-11-18 00:00:00	2	\N	\N
16	127	2	11	Whole Chicken	EA	20.000	80.0000	0.000	0.00	1600.00	15.000	240.00	1600.00	1840.00	\N	active	2025-11-18 00:00:00	2	\N	\N
18	129	1	14	Frozen Pizza	EA	100.000	0.0000	0.000	0.00	0.00	15.000	0.00	0.00	0.00	\N	active	2025-11-18 08:25:09.697	4	\N	\N
19	129	2	10	5Lt Cooking Oil	EA	85.000	8.5000	0.000	0.00	722.50	15.000	108.38	722.50	830.88	\N	active	2025-11-18 08:25:09.703	3	\N	\N
30	138	1	11	Whole Chicken	\N	50.000	80.0000	0.000	0.00	4000.00	15.000	600.00	4000.00	4600.00	\N	active	2025-11-19 12:38:55	4	\N	\N
31	139	1	11	Whole Chicken	\N	50.000	80.0000	0.000	0.00	4000.00	15.000	600.00	4000.00	4600.00	\N	active	2025-11-19 13:00:36	4	\N	\N
32	140	1	17	Full CHicken	\N	50.000	12.0000	0.000	0.00	600.00	15.000	90.00	600.00	690.00	\N	active	2025-11-19 13:03:58	4	\N	\N
33	142	1	14	Frozen Pizza	\N	100.000	10.0000	0.000	0.00	1000.00	15.000	150.00	1000.00	1150.00	\N	active	2025-11-19 13:09:19	3	\N	\N
34	143	1	12	2% Milk	\N	150.000	7.0000	0.000	0.00	1050.00	15.000	157.50	1050.00	1207.50	\N	active	2025-11-19 14:18:35	4	\N	\N
35	144	1	14	Frozen Pizza	\N	150.000	10.0000	0.000	0.00	1500.00	15.000	225.00	1500.00	1725.00	\N	active	2025-11-19 15:20:08	4	\N	\N
38	147	1	22	10KG Butternut	\N	100.000	25.0000	10.000	250.00	2500.00	15.000	337.50	2250.00	2587.50	\N	active	2025-11-20 16:40:47	4	\N	\N
\.


--
-- TOC entry 5905 (class 0 OID 36477)
-- Dependencies: 280
-- Data for Name: pu30_ord_hdr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pu30_ord_hdr (id, doc_no, ref_no, trans_date, supp_id, supp_name, supp_phone, supp_email, supp_address1, supp_address2, supp_address3, supp_postal_code, supp_vat_no, supp_payment_terms, gross_tot, disc_tot, vat_tot, net_tot, notes, status, created_at, updated_at, deleted_at, created_by, updated_by) FROM stdin;
22	1	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
23	23	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
24	24	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
25	25	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
26	26	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
27	27	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
28	28	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
29	29	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
30	30	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
31	31	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
32	32	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
33	33	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
34	34	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
35	35	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
36	36	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
37	37	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
38	38	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
39	39	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
43	40	\N	2025-11-12	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
44	44	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
45	45	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
46	46	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
47	47	\N	2025-11-12	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-12 00:00:00	\N	\N	2	\N
48	48	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
49	49	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
50	50	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
51	51	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
52	52	\N	2025-11-13	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
53	53	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
54	54	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
55	55	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
56	56	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
59	57	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
60	60	ref3098	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
61	61	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
62	62	\N	2025-11-13	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	3	\N
63	63	refio	2025-11-13	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
64	64	REF58	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
65	65	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
66	66	\N	2025-11-13	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-13 00:00:00	\N	\N	2	\N
67	67	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
68	68	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
69	69	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
70	70	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
71	71	\N	2025-11-14	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	4	\N
72	72	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
73	73	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
74	74	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
75	75	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
76	76	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
77	77	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
78	78	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
79	79	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
80	80	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
81	81	\N	2025-11-14	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-14 00:00:00	\N	\N	2	\N
82	82	\N	2025-11-17	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
83	83	\N	2025-11-17	5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	4	\N
84	84	\N	2025-11-17	3	\N	\N	\N	\N	\N	\N	\N	\N	\N	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
85	85	\N	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
86	86	\N	2025-11-17	5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
87	87	\N	2025-11-17	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
88	88	\N	2025-11-17	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
89	89	\N	2025-11-17	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
90	90	frefr	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
91	91	\N	2025-11-17	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
92	92	\N	2025-11-17	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
93	93	\N	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
94	94	\N	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
95	95	\N	2025-11-17	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
96	96	\N	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
97	97	\N	2025-11-17	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
98	98	\N	2025-11-17	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
99	99	\N	2025-11-17	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
100	100	\N	2025-11-17	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
101	101	\N	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
102	102	\N	2025-11-17	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
103	103	\N	2025-11-17	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	4	\N
104	104	\N	2025-11-17	5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
105	105	\N	2025-11-17	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
106	106	\N	2025-11-17	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	4	\N
107	107	\N	2025-11-17	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
108	108	\N	2025-11-17	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	4	\N
109	109	\N	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
110	110	\N	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	3	\N
111	111	\N	2025-11-17	5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
112	112	\N	2025-11-17	5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
113	113	\N	2025-11-17	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
114	114	\N	2025-11-17	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
115	115	\N	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
116	116	\N	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
117	117	\N	2025-11-17	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
118	118	\N	2025-11-17	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
119	119	\N	2025-11-17	5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
120	120	\N	2025-11-17	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-17 00:00:00	\N	\N	2	\N
121	121	\N	2025-11-17	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	85.00	0.00	12.75	97.75	\N	posted	2025-11-17 00:00:00	\N	\N	2	\N
122	122	\N	2025-11-17	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	85.00	0.00	12.75	97.75	\N	posted	2025-11-17 00:00:00	\N	\N	2	\N
123	123	\N	2025-11-18	3	supp 3	8323442342	supp3@info.com	add3	add3	add4	3434	\N	0	8.50	0.00	1.28	9.78	\N	posted	2025-11-18 00:00:00	\N	\N	2	\N
145	145	\N	2025-11-19	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-19 00:00:00	\N	\N	2	\N
124	124	\N	2025-11-18	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	85.00	0.00	12.75	97.75	\N	posted	2025-11-18 00:00:00	\N	\N	2	\N
125	125	\N	2025-11-18	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	85.00	0.00	12.75	97.75	\N	posted	2025-11-18 00:00:00	\N	\N	2	\N
126	126	\N	2025-11-18	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-18 00:00:00	\N	\N	3	\N
146	146	REF877	2025-11-20	6	Donny brook Spar	0125254545	info@spar.co	address 1	address 2	addres 3	4521	452112125445	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-20 16:37:40	\N	\N	2	\N
127	127	\N	2025-11-18	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	1727.50	0.00	259.13	1986.63	\N	posted	2025-11-18 00:00:00	\N	\N	2	\N
128	128	rtyuu	2025-11-18	5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-18 00:00:00	\N	\N	2	\N
129	129	\N	2025-11-18	2	supplier 2	09089898989	supp2@info.co	add23	add 3	add 4	4521	\N	30	722.50	0.00	108.38	830.88	\N	posted	2025-11-18 00:00:00	\N	\N	2	\N
130	130	REF900	2025-11-18	6	Donny brook Spar	0125254545	info@spar.co	address 1	address 2	addres 3	4521	452112125445	\N	127.50	0.00	19.13	146.63	\N	posted	2025-11-18 00:00:00	\N	\N	4	\N
131	131	USHAKA7854	2025-11-18	7	Ushaka Fruits & Veg	09090909998	ushaka@email.com	addrees 2	address 3	address 4	45896	7854125896	0	382.50	0.00	57.38	439.88	\N	posted	2025-11-18 00:00:00	\N	\N	4	\N
132	132	\N	2025-11-18	7	Ushaka Fruits & Veg	0909090999	ushaka@email.com	addrees 2	address 3	address 4	45896	7854125896	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-18 00:00:00	\N	\N	2	\N
133	133	\N	2025-11-18	7	Ushaka Fruits & Veg	0909090999	ushaka@email.com	addrees 2	address 3	address 4	45896	7854125896	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-18 00:00:00	\N	\N	2	\N
134	134	\N	2025-11-18	7	Ushaka Fruits & Veg	0909090999	ushaka@email.com	addrees 2	address 3	address 4	45896	7854125896	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-18 00:00:00	\N	\N	2	\N
135	135	NAZO	2025-11-18	7	Ushaka Fruits & Veg	0909090999	ushaka@email.com	addrees 2	address 3	address 4	45896	7854125896	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-18 00:00:00	\N	\N	4	\N
136	136	\N	2025-11-18	7	Ushaka Fruits & Veg	0909090999	ushaka@email.com	addrees 2	address 3	address 4	45896	7854125896	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-18 00:00:00	\N	\N	4	\N
137	137	\N	2025-11-19	6	Donny brook Spar	0125254545	info@spar.co	address 1	address 2	addres 3	4521	452112125445	\N	0.00	0.00	0.00	0.00	\N	draft	2025-11-19 00:00:00	\N	\N	2	\N
138	138	\N	2025-11-19	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	4000.00	0.00	600.00	4600.00	\N	posted	2025-11-19 12:38:55	2025-11-19 12:38:55	\N	2	\N
139	139	\N	2025-11-19	5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	4000.00	0.00	600.00	4600.00	\N	posted	2025-11-19 13:00:36	2025-11-19 13:00:36	\N	2	\N
140	140	\N	2025-11-19	6	Donny brook Spar	0125254545	info@spar.co	address 1	address 2	addres 3	4521	452112125445	\N	600.00	0.00	90.00	690.00	\N	posted	2025-11-19 13:03:58	2025-11-19 13:03:58	\N	2	\N
141	141	\N	2025-11-19	6	Donny brook Spar	0125254545	info@spar.co	address 1	address 2	addres 3	4521	452112125445	\N	0.00	0.00	0.00	0.00	\N	draft	2025-11-19 13:08:48	\N	\N	2	\N
142	142	ORD125	2025-11-19	6	Donny brook Spar	0125254545	info@spar.co	address 1	address 2	addres 3	4521	452112125445	0	1000.00	0.00	150.00	1150.00	\N	posted	2025-11-19 13:09:19	2025-11-19 13:09:19	\N	4	\N
143	143	\N	2025-11-19	4	Dube Logistics	0101012365	dube@logi.co	add90	add98	add32	9089	78541254	0	1050.00	0.00	157.50	1207.50	\N	posted	2025-11-19 14:18:35	2025-11-19 14:18:35	\N	2	\N
144	144	\N	2025-11-19	5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	1500.00	0.00	225.00	1725.00	\N	posted	2025-11-19 15:20:08	2025-11-19 15:20:08	\N	2	\N
147	147	\N	2025-11-20	5	Zinhle	0909090909	info@hello.co	add1	add2	add3	1452	7458754	30	2500.00	250.00	337.50	2587.50	\N	posted	2025-11-20 16:40:47	2025-11-20 16:40:47	\N	2	\N
148	148	\N	2025-11-21	2	supplier 2	0908989898	supp2@info.co	add23	add 3	add 4	4521	\N	30	0.00	0.00	0.00	0.00	\N	draft	2025-11-21 00:00:00	\N	\N	2	\N
149	149	\N	2025-11-21	1	supplier 1	0124521252	info@suppl.co	add1	add1	add2	1254	7856698562	0	0.00	0.00	0.00	0.00	\N	draft	2025-11-21 10:20:35	\N	\N	2	\N
\.


--
-- TOC entry 5909 (class 0 OID 36562)
-- Dependencies: 284
-- Data for Name: pu30_ord_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pu30_ord_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5913 (class 0 OID 36619)
-- Dependencies: 288
-- Data for Name: pu31_grn_det; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pu31_grn_det (id, hdr_id, line_no, stock_id, item_name, uom, batch_id, expiry_date, qnty, unit_cost, disc_pct, disc_amt, gross_amt, vat_rate, vat_amt, net_excl_amt, line_total, po_line_id, wh_id, wb_id, notes, status, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- TOC entry 5911 (class 0 OID 36582)
-- Dependencies: 286
-- Data for Name: pu31_grn_hdr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pu31_grn_hdr (id, doc_no, ref_doc_type, ref_doc_no, trans_date, supp_id, supp_name, supp_phone, supp_email, supp_address1, supp_address2, supp_address3, supp_postal_code, supp_vat_no, supp_payment_terms, delivery_note_no, carrier_name, received_by, gross_tot, vat_tot, net_tot, status, created_at, updated_at, deleted_at, created_by, updated_by) FROM stdin;
\.


--
-- TOC entry 5915 (class 0 OID 36671)
-- Dependencies: 290
-- Data for Name: pu31_grn_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pu31_grn_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5919 (class 0 OID 36724)
-- Dependencies: 294
-- Data for Name: pu32_inv_det; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pu32_inv_det (id, hdr_id, line_no, stock_id, item_name, uom, batch_id, expiry_date, qnty, unit_cost, disc_pct, disc_amt, gross_amt, vat_rate, vat_amt, net_excl_amt, line_total, wh_id, wb_id, notes, status, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- TOC entry 5917 (class 0 OID 36691)
-- Dependencies: 292
-- Data for Name: pu32_inv_hdr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pu32_inv_hdr (id, doc_no, ref_doc_type, ref_doc_no, trans_date, invoice_date, due_date, payment_method, supp_id, supp_name, supp_phone, supp_email, supp_address1, supp_address2, supp_address3, supp_postal_code, supp_vat_no, supp_payment_terms, supp_bank_name, supp_bank_account, supp_bank_branch, gross_tot, disc_tot, vat_tot, net_tot, status, created_at, updated_at, deleted_at, created_by, updated_by) FROM stdin;
\.


--
-- TOC entry 5921 (class 0 OID 36776)
-- Dependencies: 296
-- Data for Name: pu32_inv_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pu32_inv_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5925 (class 0 OID 36829)
-- Dependencies: 300
-- Data for Name: sa30_quo_det; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa30_quo_det (id, hdr_id, line_no, stock_id, item_name, uom, qnty, unit_price, disc_pct, disc_amt, gross_amt, vat_rate, vat_amt, net_excl_amt, line_total, wh_id, wb_id, notes, status, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- TOC entry 5923 (class 0 OID 36796)
-- Dependencies: 298
-- Data for Name: sa30_quo_hdr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa30_quo_hdr (id, doc_no, ref_no, trans_date, cust_id, cust_name, cust_phone, cust_email, cust_address1, cust_address2, cust_address3, cust_postal_code, cust_vat_no, cust_payment_terms, gross_tot, disc_tot, vat_tot, net_tot, notes, status, created_at, updated_at, deleted_at, created_by, updated_by) FROM stdin;
\.


--
-- TOC entry 5927 (class 0 OID 36881)
-- Dependencies: 302
-- Data for Name: sa30_quo_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa30_quo_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5931 (class 0 OID 36934)
-- Dependencies: 306
-- Data for Name: sa31_ord_det; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa31_ord_det (id, hdr_id, line_no, stock_id, item_name, uom, qnty, unit_price, disc_pct, disc_amt, gross_amt, vat_rate, vat_amt, net_excl_amt, line_total, wh_id, wb_id, notes, status, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- TOC entry 5929 (class 0 OID 36901)
-- Dependencies: 304
-- Data for Name: sa31_ord_hdr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa31_ord_hdr (id, doc_no, ref_doc_type, ref_doc_no, trans_date, cust_id, cust_name, cust_phone, cust_email, cust_address1, cust_address2, cust_address3, cust_postal_code, cust_vat_no, cust_payment_terms, gross_tot, disc_tot, vat_tot, net_tot, notes, status, created_at, updated_at, deleted_at, created_by, updated_by) FROM stdin;
\.


--
-- TOC entry 5933 (class 0 OID 36986)
-- Dependencies: 308
-- Data for Name: sa31_ord_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa31_ord_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5937 (class 0 OID 37039)
-- Dependencies: 312
-- Data for Name: sa32_inv_det; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa32_inv_det (id, hdr_id, line_no, stock_id, item_name, uom, qnty, unit_price, disc_pct, disc_amt, gross_amt, vat_rate, vat_amt, net_excl_amt, line_total, wh_id, wb_id, notes, status, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- TOC entry 5935 (class 0 OID 37006)
-- Dependencies: 310
-- Data for Name: sa32_inv_hdr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa32_inv_hdr (id, doc_no, ref_doc_type, ref_doc_no, trans_date, due_date, cust_id, cust_name, cust_phone, cust_email, cust_address1, cust_address2, cust_address3, cust_postal_code, cust_vat_no, cust_payment_terms, gross_tot, disc_tot, vat_tot, net_tot, notes, status, created_at, updated_at, deleted_at, created_by, updated_by) FROM stdin;
\.


--
-- TOC entry 5939 (class 0 OID 37091)
-- Dependencies: 314
-- Data for Name: sa32_inv_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa32_inv_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5943 (class 0 OID 37144)
-- Dependencies: 318
-- Data for Name: sa33_crn_det; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa33_crn_det (id, hdr_id, line_no, stock_id, item_name, uom, qnty, unit_price, disc_pct, disc_amt, gross_amt, vat_rate, vat_amt, net_amt, line_total, wh_id, wb_id, notes, status, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- TOC entry 5941 (class 0 OID 37111)
-- Dependencies: 316
-- Data for Name: sa33_crn_hdr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa33_crn_hdr (id, doc_no, ref_doc_type, ref_doc_no, trans_date, credit_date, cust_id, cust_name, cust_phone, cust_email, cust_address1, cust_address2, cust_address3, cust_postal_code, cust_vat_no, cust_payment_terms, gross_tot, disc_tot, vat_tot, net_tot, notes, status, created_at, updated_at, deleted_at, created_by, updated_by) FROM stdin;
\.


--
-- TOC entry 5945 (class 0 OID 37196)
-- Dependencies: 320
-- Data for Name: sa33_crn_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sa33_crn_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5880 (class 0 OID 36189)
-- Dependencies: 255
-- Data for Name: st01_mast; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.st01_mast (id, stock_code, description, barcode, batch_control, has_expiry_date, category_id, unit_cost, sell_price, stock_on_hand, total_purch, total_sales, reserved_qnty, status, created_at, updated_at, deleted_at, created_by, uom, stock_balance, stock_ordered) FROM stdin;
17	17	Full CHicken	\N	\N	\N	5	12.0000	48.9000	0.000	0.000	0.000	0.000	active	2025-11-17 00:00:00	\N	\N	2	BX	\N	\N
13	13	Loaf of Sliced Bread	\N	t	\N	8	8.0000	20.0000	0.000	0.000	0.000	0.000	active	2025-11-14 00:00:00	\N	\N	3	EA	\N	\N
10	1	5Lt Cooking Oil	\N	t	\N	3	8.5000	15.0000	50.000	0.000	0.000	0.000	active	2025-11-12 00:00:00	\N	\N	2	L	\N	\N
11	11	Whole Chicken	\N	\N	\N	9	80.0000	150.0000	0.000	0.000	0.000	0.000	active	2025-11-14 00:00:00	\N	\N	2	KG	\N	\N
12	12	2% Milk	\N	\N	\N	4	7.0000	20.0000	0.000	0.000	0.000	0.000	active	2025-11-14 00:00:00	\N	\N	4	L	\N	\N
14	14	Frozen Pizza	\N	\N	\N	9	10.0000	45.0000	0.000	0.000	0.000	0.000	active	2025-11-14 00:00:00	\N	\N	3	CM	\N	\N
16	15	500G Tingles Tomato	\N	\N	\N	3	8.5000	16.0000	0.000	0.000	0.000	0.000	active	2025-11-14 00:00:00	\N	\N	2	G	\N	\N
18	18	Testing new item	\N	t	\N	5	20.0000	55.0000	0.000	0.000	0.000	0.000	active	2025-11-20 16:16:41.286	\N	\N	2	KG	\N	\N
20	19	10KG Potatoes	\N	\N	\N	13	15.0000	35.0000	0.000	0.000	0.000	0.000	active	2025-11-20 16:19:10.25	\N	\N	2	KG	\N	\N
22	21	10KG Butternut	\N	t	\N	13	25.0000	45.0000	0.000	0.000	0.000	0.000	active	2025-11-20 16:20:55.492	\N	\N	2	KG	\N	\N
24	23	10KG Onion	\N	t	\N	13	15.0000	35.0000	0.000	0.000	0.000	0.000	active	2025-11-20 16:23:10.576	\N	\N	2	KG	\N	\N
\.


--
-- TOC entry 5878 (class 0 OID 36173)
-- Dependencies: 253
-- Data for Name: st02_cat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.st02_cat (id, cat_code, cat_name, description, status, created_at, updated_at, deleted_at, created_by) FROM stdin;
6	CAT6	Raw Meat/Poultry	Raw Meat/Poultry	active	2025-11-14 10:54:29.154	\N	\N	3
1	CAT1	Maize	Maize	active	2025-11-12 12:54:15.089	\N	\N	2
3	CAT2	COOKING OIL	COOKING OIL	active	2025-11-12 12:56:03.081	\N	\N	2
4	CAT4	RED MEAT	RED MEAT	active	2025-11-13 07:58:22.486	\N	\N	2
5	CAT5	Perishable Produce	Perishable Produce	active	2025-11-14 10:54:07.884	\N	\N	2
8	CAT7	Bakery	Bakery	active	2025-11-14 10:54:58.533	\N	\N	4
9	CAT9	Frozen Food	Frozen Food	active	2025-11-14 10:55:08.684	\N	\N	3
11	CAT10	Fragile Item	Fragile Item	active	2025-11-14 10:57:10.236	\N	\N	2
12	CAT12	Non-Food Household	Non-Food Household	active	2025-11-14 10:57:32.312	\N	\N	2
13	CAT13	Vegetable	Vegetable	0	2025-11-16 23:16:27.345	\N	\N	2
14	CAT14	New Category	New Category	0	2025-11-21 08:14:28.214	\N	\N	2
\.


--
-- TOC entry 5957 (class 0 OID 37848)
-- Dependencies: 332
-- Data for Name: st03_uom_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.st03_uom_master (id, uom_code, uom_name, uom_type, status, created_at) FROM stdin;
1	EA	Each	UNIT	true	2025-11-12 16:38:42.022933
2	PK	Pack	UNIT	true	2025-11-12 16:38:42.022933
3	BX	Box	UNIT	true	2025-11-12 16:38:42.022933
4	KG	Kilogram	WEIGHT	true	2025-11-12 16:38:42.022933
5	G	Gram	WEIGHT	true	2025-11-12 16:38:42.022933
6	LB	Pound	WEIGHT	true	2025-11-12 16:38:42.022933
7	L	Liter	VOLUME	true	2025-11-12 16:38:42.022933
8	ML	Milliliter	VOLUME	true	2025-11-12 16:38:42.022933
9	M	Meter	LENGTH	true	2025-11-12 16:38:42.022933
10	CM	Centimeter	LENGTH	true	2025-11-12 16:38:42.022933
\.


--
-- TOC entry 5959 (class 0 OID 37918)
-- Dependencies: 334
-- Data for Name: st04_stock_uom; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.st04_stock_uom (id, stock_id, uom_id, is_base_uom, conversion_factor, barcode, unit_cost, sell_price, is_active, display_order, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5961 (class 0 OID 37970)
-- Dependencies: 336
-- Data for Name: st30_trans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.st30_trans (id, stock_id, trans_date, doc_type, direction, qnty, unit_cost, sell_price, batch_id, expiry_date, notes) FROM stdin;
1	14	2025-11-19	PO	IN	150.00	10.00	0.00	\N	\N	Converted to GRN - PO#144 Line 1
2	22	2025-11-20	PO	IN	100.00	25.00	0.00	\N	\N	Converted to GRN - PO#147 Line 1
\.


--
-- TOC entry 5883 (class 0 OID 36257)
-- Dependencies: 258
-- Data for Name: st40_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.st40_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5849 (class 0 OID 35917)
-- Dependencies: 224
-- Data for Name: sy00_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sy00_user (id, username, full_name, phone, email, password, status, role_id, created_at, updated_at, deleted_at) FROM stdin;
1	bongani	Bongani DLamini	0125478564	info@hello.com	5f4dcc3b5aa765d61d8327deb882cf99	active	1	2025-11-11 10:44:53.644	2025-11-12 14:36:07.973	\N
2	sihleduma	Sihle Duma	0121212121	sihle@info.com	5f4dcc3b5aa765d61d8327deb882cf99	active	3	2025-11-11 10:45:28.73	2025-11-12 14:36:22.214	\N
4	newuser	new user	0123652365	newuser@newuser.com	5f4dcc3b5aa765d61d8327deb882cf99	active	3	2025-11-13 12:31:48.964	\N	\N
5	nonhle	nonhle	0147852369	nonhle@helo.com	5f4dcc3b5aa765d61d8327deb882cf99	active	2	2025-11-13 12:32:23.94	\N	\N
6	nosihle	Nosihkle Duma	0123652635	hello@moto.co	5f4dcc3b5aa765d61d8327deb882cf99	active	1	2025-11-14 08:55:28.405	\N	\N
7	donald	Donald Lamola	0147852369	don@hello.com	5f4dcc3b5aa765d61d8327deb882cf99	active	1	2025-11-14 08:56:10.565	\N	\N
9	manager1	Manager One	\N	manager1@example.com	$2a$12$V5xn7XLriGXJxbgleV4T2u.miZUg.Yb4Nmfwlbptl9tFYTmcsu8P.	1	\N	2025-11-14 14:10:12.512471	\N	\N
10	manager2	Manager Two	\N	manager2@example.com	$2a$12$V5xn7XLriGXJxbgleV4T2u.miZUg.Yb4Nmfwlbptl9tFYTmcsu8P.	1	\N	2025-11-14 14:10:12.512471	\N	\N
11	manager3	Manager Three	\N	manager3@example.com	$2a$12$V5xn7XLriGXJxbgleV4T2u.miZUg.Yb4Nmfwlbptl9tFYTmcsu8P.	1	\N	2025-11-14 14:10:12.512471	\N	\N
12	clerk1	Clerk One	\N	clerk1@example.com	$2a$12$V5xn7XLriGXJxbgleV4T2u.miZUg.Yb4Nmfwlbptl9tFYTmcsu8P.	1	\N	2025-11-14 14:10:12.512471	\N	\N
13	clerk2	Clerk Two	\N	clerk2@example.com	$2a$12$V5xn7XLriGXJxbgleV4T2u.miZUg.Yb4Nmfwlbptl9tFYTmcsu8P.	1	\N	2025-11-14 14:10:12.512471	\N	\N
14	clerk3	Clerk Three	\N	clerk3@example.com	$2a$12$V5xn7XLriGXJxbgleV4T2u.miZUg.Yb4Nmfwlbptl9tFYTmcsu8P.	1	\N	2025-11-14 14:10:12.512471	\N	\N
15	clerk4	Clerk Four	\N	clerk4@example.com	$2a$12$V5xn7XLriGXJxbgleV4T2u.miZUg.Yb4Nmfwlbptl9tFYTmcsu8P.	1	\N	2025-11-14 14:10:12.512471	\N	\N
16	clerk5	Clerk Five	\N	clerk5@example.com	$2a$12$V5xn7XLriGXJxbgleV4T2u.miZUg.Yb4Nmfwlbptl9tFYTmcsu8P.	1	\N	2025-11-14 14:10:12.512471	\N	\N
17	clerk6	Clerk Six	\N	clerk6@example.com	$2a$12$V5xn7XLriGXJxbgleV4T2u.miZUg.Yb4Nmfwlbptl9tFYTmcsu8P.	1	\N	2025-11-14 14:10:12.512471	\N	\N
3	admin	admin user	0123652635	info@admin.co	5f4dcc3b5aa765d61d8327deb882cf99	active	1	2025-11-13 12:31:20.921	2025-11-17 09:19:31.322	\N
\.


--
-- TOC entry 5851 (class 0 OID 35935)
-- Dependencies: 226
-- Data for Name: sy01_sess; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sy01_sess (id, user_id, uuid, login_time, logout_time) FROM stdin;
\.


--
-- TOC entry 5853 (class 0 OID 35948)
-- Dependencies: 228
-- Data for Name: sy02_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sy02_logs (id, user_id, level, action, details, created_at) FROM stdin;
\.


--
-- TOC entry 5855 (class 0 OID 35963)
-- Dependencies: 230
-- Data for Name: sy03_sett; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sy03_sett (id, sett_key, sett_value, description, updated_at) FROM stdin;
1	company.name	XACT Demo Company	Company legal/trading name	2025-11-14 14:10:38.30954
2	company.vat_no	ZA-123456789	VAT number	2025-11-14 14:10:38.30954
3	ui.theme	dark	Default UI theme	2025-11-14 14:10:38.30954
\.


--
-- TOC entry 5843 (class 0 OID 35876)
-- Dependencies: 218
-- Data for Name: sy04_role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sy04_role (id, role_name, status, created_at, updated_at, deleted_at) FROM stdin;
1	ADMIN	active	2025-11-12 00:00:00	\N	\N
2	MANAGER	active	2025-11-12 00:00:00	\N	\N
3	CLERK	active	2025-11-12 00:00:00	\N	\N
4	Admin	active	2025-11-14 14:10:38.30954	\N	\N
5	Manager	active	2025-11-14 14:10:38.30954	\N	\N
6	Clerk	active	2025-11-14 14:10:38.30954	\N	\N
\.


--
-- TOC entry 5845 (class 0 OID 35887)
-- Dependencies: 220
-- Data for Name: sy05_perm; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sy05_perm (id, perm_name, description, perm_code, status, created_at, updated_at, deleted_at, created_by) FROM stdin;
1	sy.user.view	VIEW permission for sy00_user (sy.user)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
2	sy.user.create	CREATE permission for sy00_user (sy.user)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
3	sy.user.update	UPDATE permission for sy00_user (sy.user)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
4	sy.user.delete	DELETE permission for sy00_user (sy.user)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
5	sy.user.manage	MANAGE permission for sy00_user (sy.user)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
6	sy.role.view	VIEW permission for sy04_role (sy.role)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
7	sy.role.create	CREATE permission for sy04_role (sy.role)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
8	sy.role.update	UPDATE permission for sy04_role (sy.role)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
9	sy.role.delete	DELETE permission for sy04_role (sy.role)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
10	sy.role.manage	MANAGE permission for sy04_role (sy.role)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
11	sy.permission.view	VIEW permission for sy05_perm (sy.permission)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
12	sy.permission.create	CREATE permission for sy05_perm (sy.permission)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
13	sy.permission.update	UPDATE permission for sy05_perm (sy.permission)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
14	sy.permission.delete	DELETE permission for sy05_perm (sy.permission)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
15	sy.permission.manage	MANAGE permission for sy05_perm (sy.permission)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
16	sy.role_permission.view	VIEW permission for sy06_role_perm (sy.role_permission)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
17	sy.role_permission.create	CREATE permission for sy06_role_perm (sy.role_permission)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
18	sy.role_permission.update	UPDATE permission for sy06_role_perm (sy.role_permission)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
19	sy.role_permission.delete	DELETE permission for sy06_role_perm (sy.role_permission)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
20	sy.role_permission.manage	MANAGE permission for sy06_role_perm (sy.role_permission)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
21	sy.session.view	VIEW permission for sy01_sess (sy.session)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
22	sy.session.create	CREATE permission for sy01_sess (sy.session)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
23	sy.session.update	UPDATE permission for sy01_sess (sy.session)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
24	sy.session.delete	DELETE permission for sy01_sess (sy.session)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
25	sy.session.manage	MANAGE permission for sy01_sess (sy.session)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
26	sy.log.view	VIEW permission for sy02_logs (sy.log)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
27	sy.log.create	CREATE permission for sy02_logs (sy.log)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
28	sy.log.update	UPDATE permission for sy02_logs (sy.log)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
29	sy.log.delete	DELETE permission for sy02_logs (sy.log)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
30	sy.log.manage	MANAGE permission for sy02_logs (sy.log)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
31	sy.setting.view	VIEW permission for sy03_sett (sy.setting)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
32	sy.setting.create	CREATE permission for sy03_sett (sy.setting)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
33	sy.setting.update	UPDATE permission for sy03_sett (sy.setting)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
34	sy.setting.delete	DELETE permission for sy03_sett (sy.setting)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
35	sy.setting.manage	MANAGE permission for sy03_sett (sy.setting)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
36	sy.history.view	VIEW permission for sy40_hist (sy.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
37	sy.history.create	CREATE permission for sy40_hist (sy.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
38	sy.history.update	UPDATE permission for sy40_hist (sy.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
39	sy.history.delete	DELETE permission for sy40_hist (sy.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
40	sy.history.manage	MANAGE permission for sy40_hist (sy.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
41	dl.customer.view	VIEW permission for dl01_mast (dl.customer)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
42	dl.customer.create	CREATE permission for dl01_mast (dl.customer)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
43	dl.customer.update	UPDATE permission for dl01_mast (dl.customer)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
44	dl.customer.delete	DELETE permission for dl01_mast (dl.customer)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
45	dl.customer.manage	MANAGE permission for dl01_mast (dl.customer)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
46	dl.transaction.view	VIEW permission for dl30_trans (dl.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
47	dl.transaction.create	CREATE permission for dl30_trans (dl.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
48	dl.transaction.update	UPDATE permission for dl30_trans (dl.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
49	dl.transaction.delete	DELETE permission for dl30_trans (dl.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
50	dl.transaction.manage	MANAGE permission for dl30_trans (dl.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
51	dl.history.view	VIEW permission for dl40_hist (dl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
52	dl.history.create	CREATE permission for dl40_hist (dl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
53	dl.history.update	UPDATE permission for dl40_hist (dl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
54	dl.history.delete	DELETE permission for dl40_hist (dl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
55	dl.history.manage	MANAGE permission for dl40_hist (dl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
56	cl.supplier.view	VIEW permission for cl01_mast (cl.supplier)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
57	cl.supplier.create	CREATE permission for cl01_mast (cl.supplier)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
58	cl.supplier.update	UPDATE permission for cl01_mast (cl.supplier)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
59	cl.supplier.delete	DELETE permission for cl01_mast (cl.supplier)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
60	cl.supplier.manage	MANAGE permission for cl01_mast (cl.supplier)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
61	cl.transaction.view	VIEW permission for cl30_trans (cl.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
62	cl.transaction.create	CREATE permission for cl30_trans (cl.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
63	cl.transaction.update	UPDATE permission for cl30_trans (cl.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
64	cl.transaction.delete	DELETE permission for cl30_trans (cl.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
65	cl.transaction.manage	MANAGE permission for cl30_trans (cl.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
66	cl.history.view	VIEW permission for cl40_hist (cl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
67	cl.history.create	CREATE permission for cl40_hist (cl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
68	cl.history.update	UPDATE permission for cl40_hist (cl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
69	cl.history.delete	DELETE permission for cl40_hist (cl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
70	cl.history.manage	MANAGE permission for cl40_hist (cl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
71	st.category.view	VIEW permission for st02_mast (st.category)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
72	st.category.create	CREATE permission for st02_mast (st.category)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
73	st.category.update	UPDATE permission for st02_mast (st.category)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
74	st.category.delete	DELETE permission for st02_mast (st.category)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
75	st.category.manage	MANAGE permission for st02_mast (st.category)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
76	st.item.view	VIEW permission for st01_mast (st.item)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
77	st.item.create	CREATE permission for st01_mast (st.item)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
78	st.item.update	UPDATE permission for st01_mast (st.item)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
79	st.item.delete	DELETE permission for st01_mast (st.item)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
80	st.item.manage	MANAGE permission for st01_mast (st.item)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
81	st.transaction.view	VIEW permission for st30_trans (st.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
82	st.transaction.create	CREATE permission for st30_trans (st.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
83	st.transaction.update	UPDATE permission for st30_trans (st.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
84	st.transaction.delete	DELETE permission for st30_trans (st.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
85	st.transaction.manage	MANAGE permission for st30_trans (st.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
86	st.history.view	VIEW permission for st40_hist (st.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
87	st.history.create	CREATE permission for st40_hist (st.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
88	st.history.update	UPDATE permission for st40_hist (st.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
89	st.history.delete	DELETE permission for st40_hist (st.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
90	st.history.manage	MANAGE permission for st40_hist (st.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
91	wh.warehouse.view	VIEW permission for wh01_mast (wh.warehouse)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
92	wh.warehouse.create	CREATE permission for wh01_mast (wh.warehouse)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
93	wh.warehouse.update	UPDATE permission for wh01_mast (wh.warehouse)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
94	wh.warehouse.delete	DELETE permission for wh01_mast (wh.warehouse)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
95	wh.warehouse.manage	MANAGE permission for wh01_mast (wh.warehouse)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
96	wh.allowed_category.view	VIEW permission for wh02_mast (wh.allowed_category)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
97	wh.allowed_category.create	CREATE permission for wh02_mast (wh.allowed_category)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
98	wh.allowed_category.update	UPDATE permission for wh02_mast (wh.allowed_category)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
99	wh.allowed_category.delete	DELETE permission for wh02_mast (wh.allowed_category)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
100	wh.allowed_category.manage	MANAGE permission for wh02_mast (wh.allowed_category)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
101	wh.transaction.view	VIEW permission for wh30_trans (wh.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
102	wh.transaction.create	CREATE permission for wh30_trans (wh.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
103	wh.transaction.update	UPDATE permission for wh30_trans (wh.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
104	wh.transaction.delete	DELETE permission for wh30_trans (wh.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
105	wh.transaction.manage	MANAGE permission for wh30_trans (wh.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
106	wh.history.view	VIEW permission for wh40_hist (wh.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
107	wh.history.create	CREATE permission for wh40_hist (wh.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
108	wh.history.update	UPDATE permission for wh40_hist (wh.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
109	wh.history.delete	DELETE permission for wh40_hist (wh.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
110	wh.history.manage	MANAGE permission for wh40_hist (wh.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
111	wb.bin.view	VIEW permission for wb01_mast (wb.bin)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
112	wb.bin.create	CREATE permission for wb01_mast (wb.bin)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
113	wb.bin.update	UPDATE permission for wb01_mast (wb.bin)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
114	wb.bin.delete	DELETE permission for wb01_mast (wb.bin)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
115	wb.bin.manage	MANAGE permission for wb01_mast (wb.bin)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
116	wb.transaction.view	VIEW permission for wb30_trans (wb.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
117	wb.transaction.create	CREATE permission for wb30_trans (wb.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
118	wb.transaction.update	UPDATE permission for wb30_trans (wb.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
119	wb.transaction.delete	DELETE permission for wb30_trans (wb.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
120	wb.transaction.manage	MANAGE permission for wb30_trans (wb.transaction)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
121	wb.history.view	VIEW permission for wb40_hist (wb.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
122	wb.history.create	CREATE permission for wb40_hist (wb.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
123	wb.history.update	UPDATE permission for wb40_hist (wb.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
124	wb.history.delete	DELETE permission for wb40_hist (wb.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
125	wb.history.manage	MANAGE permission for wb40_hist (wb.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
126	sa.base_hdr.view	VIEW permission for sa30_hdr (sa.base_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
127	sa.base_hdr.create	CREATE permission for sa30_hdr (sa.base_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
128	sa.base_hdr.update	UPDATE permission for sa30_hdr (sa.base_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
129	sa.base_hdr.delete	DELETE permission for sa30_hdr (sa.base_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
130	sa.base_hdr.manage	MANAGE permission for sa30_hdr (sa.base_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
131	sa.base_det.view	VIEW permission for sa30_det (sa.base_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
132	sa.base_det.create	CREATE permission for sa30_det (sa.base_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
133	sa.base_det.update	UPDATE permission for sa30_det (sa.base_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
134	sa.base_det.delete	DELETE permission for sa30_det (sa.base_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
135	sa.base_det.manage	MANAGE permission for sa30_det (sa.base_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
136	sa.base_hist.view	VIEW permission for sa40_hist (sa.base_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
137	sa.base_hist.create	CREATE permission for sa40_hist (sa.base_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
138	sa.base_hist.update	UPDATE permission for sa40_hist (sa.base_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
139	sa.base_hist.delete	DELETE permission for sa40_hist (sa.base_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
140	sa.base_hist.manage	MANAGE permission for sa40_hist (sa.base_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
141	sa.quote_hdr.view	VIEW permission for sa31_hdr (sa.quote_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
142	sa.quote_hdr.create	CREATE permission for sa31_hdr (sa.quote_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
143	sa.quote_hdr.update	UPDATE permission for sa31_hdr (sa.quote_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
144	sa.quote_hdr.delete	DELETE permission for sa31_hdr (sa.quote_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
145	sa.quote_hdr.manage	MANAGE permission for sa31_hdr (sa.quote_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
146	sa.quote_det.view	VIEW permission for sa31_det (sa.quote_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
147	sa.quote_det.create	CREATE permission for sa31_det (sa.quote_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
148	sa.quote_det.update	UPDATE permission for sa31_det (sa.quote_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
149	sa.quote_det.delete	DELETE permission for sa31_det (sa.quote_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
150	sa.quote_det.manage	MANAGE permission for sa31_det (sa.quote_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
151	sa.quote_hist.view	VIEW permission for sa41_hist (sa.quote_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
152	sa.quote_hist.create	CREATE permission for sa41_hist (sa.quote_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
153	sa.quote_hist.update	UPDATE permission for sa41_hist (sa.quote_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
154	sa.quote_hist.delete	DELETE permission for sa41_hist (sa.quote_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
155	sa.quote_hist.manage	MANAGE permission for sa41_hist (sa.quote_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
156	sa.invoice_hdr.view	VIEW permission for sa32_hdr (sa.invoice_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
157	sa.invoice_hdr.create	CREATE permission for sa32_hdr (sa.invoice_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
158	sa.invoice_hdr.update	UPDATE permission for sa32_hdr (sa.invoice_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
159	sa.invoice_hdr.delete	DELETE permission for sa32_hdr (sa.invoice_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
160	sa.invoice_hdr.manage	MANAGE permission for sa32_hdr (sa.invoice_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
161	sa.invoice_det.view	VIEW permission for sa32_det (sa.invoice_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
162	sa.invoice_det.create	CREATE permission for sa32_det (sa.invoice_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
163	sa.invoice_det.update	UPDATE permission for sa32_det (sa.invoice_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
164	sa.invoice_det.delete	DELETE permission for sa32_det (sa.invoice_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
165	sa.invoice_det.manage	MANAGE permission for sa32_det (sa.invoice_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
166	sa.invoice_hist.view	VIEW permission for sa42_hist (sa.invoice_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
167	sa.invoice_hist.create	CREATE permission for sa42_hist (sa.invoice_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
168	sa.invoice_hist.update	UPDATE permission for sa42_hist (sa.invoice_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
169	sa.invoice_hist.delete	DELETE permission for sa42_hist (sa.invoice_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
170	sa.invoice_hist.manage	MANAGE permission for sa42_hist (sa.invoice_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
171	sa.credit_hdr.view	VIEW permission for sa33_hdr (sa.credit_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
172	sa.credit_hdr.create	CREATE permission for sa33_hdr (sa.credit_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
173	sa.credit_hdr.update	UPDATE permission for sa33_hdr (sa.credit_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
174	sa.credit_hdr.delete	DELETE permission for sa33_hdr (sa.credit_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
175	sa.credit_hdr.manage	MANAGE permission for sa33_hdr (sa.credit_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
176	sa.credit_det.view	VIEW permission for sa33_det (sa.credit_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
177	sa.credit_det.create	CREATE permission for sa33_det (sa.credit_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
178	sa.credit_det.update	UPDATE permission for sa33_det (sa.credit_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
179	sa.credit_det.delete	DELETE permission for sa33_det (sa.credit_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
180	sa.credit_det.manage	MANAGE permission for sa33_det (sa.credit_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
181	sa.credit_hist.view	VIEW permission for sa43_hist (sa.credit_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
182	sa.credit_hist.create	CREATE permission for sa43_hist (sa.credit_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
183	sa.credit_hist.update	UPDATE permission for sa43_hist (sa.credit_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
184	sa.credit_hist.delete	DELETE permission for sa43_hist (sa.credit_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
185	sa.credit_hist.manage	MANAGE permission for sa43_hist (sa.credit_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
186	pu.invoice_hdr.view	VIEW permission for pu30_hdr (pu.invoice_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
187	pu.invoice_hdr.create	CREATE permission for pu30_hdr (pu.invoice_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
188	pu.invoice_hdr.update	UPDATE permission for pu30_hdr (pu.invoice_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
189	pu.invoice_hdr.delete	DELETE permission for pu30_hdr (pu.invoice_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
190	pu.invoice_hdr.manage	MANAGE permission for pu30_hdr (pu.invoice_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
191	pu.invoice_det.view	VIEW permission for pu30_det (pu.invoice_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
192	pu.invoice_det.create	CREATE permission for pu30_det (pu.invoice_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
193	pu.invoice_det.update	UPDATE permission for pu30_det (pu.invoice_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
194	pu.invoice_det.delete	DELETE permission for pu30_det (pu.invoice_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
195	pu.invoice_det.manage	MANAGE permission for pu30_det (pu.invoice_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
196	pu.invoice_hist.view	VIEW permission for pu40_hist (pu.invoice_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
197	pu.invoice_hist.create	CREATE permission for pu40_hist (pu.invoice_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
198	pu.invoice_hist.update	UPDATE permission for pu40_hist (pu.invoice_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
199	pu.invoice_hist.delete	DELETE permission for pu40_hist (pu.invoice_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
200	pu.invoice_hist.manage	MANAGE permission for pu40_hist (pu.invoice_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
201	pu.order_hdr.view	VIEW permission for pu31_hdr (pu.order_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
202	pu.order_hdr.create	CREATE permission for pu31_hdr (pu.order_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
203	pu.order_hdr.update	UPDATE permission for pu31_hdr (pu.order_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
204	pu.order_hdr.delete	DELETE permission for pu31_hdr (pu.order_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
205	pu.order_hdr.manage	MANAGE permission for pu31_hdr (pu.order_hdr)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
206	pu.order_det.view	VIEW permission for pu31_det (pu.order_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
207	pu.order_det.create	CREATE permission for pu31_det (pu.order_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
208	pu.order_det.update	UPDATE permission for pu31_det (pu.order_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
209	pu.order_det.delete	DELETE permission for pu31_det (pu.order_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
210	pu.order_det.manage	MANAGE permission for pu31_det (pu.order_det)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
211	pu.order_hist.view	VIEW permission for pu41_hist (pu.order_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
212	pu.order_hist.create	CREATE permission for pu41_hist (pu.order_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
213	pu.order_hist.update	UPDATE permission for pu41_hist (pu.order_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
214	pu.order_hist.delete	DELETE permission for pu41_hist (pu.order_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
215	pu.order_hist.manage	MANAGE permission for pu41_hist (pu.order_hist)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
216	gl.account.view	VIEW permission for gl01_acc (gl.account)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
217	gl.account.create	CREATE permission for gl01_acc (gl.account)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
218	gl.account.update	UPDATE permission for gl01_acc (gl.account)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
219	gl.account.delete	DELETE permission for gl01_acc (gl.account)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
220	gl.account.manage	MANAGE permission for gl01_acc (gl.account)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
221	gl.journal.view	VIEW permission for gl30_jnl (gl.journal)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
222	gl.journal.create	CREATE permission for gl30_jnl (gl.journal)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
223	gl.journal.update	UPDATE permission for gl30_jnl (gl.journal)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
224	gl.journal.delete	DELETE permission for gl30_jnl (gl.journal)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
225	gl.journal.manage	MANAGE permission for gl30_jnl (gl.journal)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
226	gl.journal_line.view	VIEW permission for gl31_det (gl.journal_line)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
227	gl.journal_line.create	CREATE permission for gl31_det (gl.journal_line)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
228	gl.journal_line.update	UPDATE permission for gl31_det (gl.journal_line)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
229	gl.journal_line.delete	DELETE permission for gl31_det (gl.journal_line)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
230	gl.journal_line.manage	MANAGE permission for gl31_det (gl.journal_line)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
231	gl.history.view	VIEW permission for gl40_hist (gl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
232	gl.history.create	CREATE permission for gl40_hist (gl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
233	gl.history.update	UPDATE permission for gl40_hist (gl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
234	gl.history.delete	DELETE permission for gl40_hist (gl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
235	gl.history.manage	MANAGE permission for gl40_hist (gl.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
236	payt.payment.view	VIEW permission for payt30_hdr (payt.payment)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
237	payt.payment.create	CREATE permission for payt30_hdr (payt.payment)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
238	payt.payment.update	UPDATE permission for payt30_hdr (payt.payment)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
239	payt.payment.delete	DELETE permission for payt30_hdr (payt.payment)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
240	payt.payment.manage	MANAGE permission for payt30_hdr (payt.payment)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
241	payt.history.view	VIEW permission for payt40_hist (payt.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
242	payt.history.create	CREATE permission for payt40_hist (payt.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
243	payt.history.update	UPDATE permission for payt40_hist (payt.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
244	payt.history.delete	DELETE permission for payt40_hist (payt.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
245	payt.history.manage	MANAGE permission for payt40_hist (payt.history)	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
246	sy.menu.access	Access SY module menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
247	sy.menu.users.access	Access SY Users Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
248	sy.menu.roles.access	Access SY Roles Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
249	sy.menu.permissions.access	Access SY Permissions Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
250	sy.menu.settings.access	Access SY Settings Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
251	sy.menu.logs.access	Access SY Logs Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
252	dl.menu.access	Access DL module menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
253	dl.menu.customers.access	Access DL Customers Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
254	dl.menu.transactions.access	Access DL Transactions Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
255	cl.menu.access	Access CL module menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
256	cl.menu.suppliers.access	Access CL Suppliers Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
257	cl.menu.transactions.access	Access CL Transactions Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
258	st.menu.access	Access ST module menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
259	st.menu.items.access	Access ST Items Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
260	st.menu.categories.access	Access ST Categories Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
261	st.menu.transactions.access	Access ST Transactions Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
262	wh.menu.access	Access WH module menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
263	wh.menu.warehouses.access	Access WH Warehouses Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
264	wb.menu.access	Access WB module menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
265	wb.menu.bins.access	Access WB Bins Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
266	wb.menu.transactions.access	Access WB Transactions Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
267	sa.menu.access	Access SA module menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
268	sa.menu.quotes.access	Access SA Quotes Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
269	sa.menu.invoices.access	Access SA Invoices Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
270	sa.menu.credits.access	Access SA Credits Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
271	pu.menu.access	Access PU module menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
272	pu.menu.orders.access	Access PU Orders Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
273	pu.menu.invoices.access	Access PU Invoices Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
274	gl.menu.access	Access GL module menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
275	gl.menu.accounts.access	Access GL Accounts Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
276	gl.menu.journals.access	Access GL Journals Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
277	gl.menu.reports.access	Access GL Reports Access menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
278	payt.menu.access	Access PAYT module menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
279	app.menu.main.access	Access main application menu	\N	1	2025-11-14 14:10:12.512471	\N	\N	\N
\.


--
-- TOC entry 5847 (class 0 OID 35898)
-- Dependencies: 222
-- Data for Name: sy06_role_perm; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sy06_role_perm (id, role_id, perm_id) FROM stdin;
1	4	1
2	4	2
3	4	3
4	4	4
5	4	5
6	4	6
7	4	7
8	4	8
9	4	9
10	4	10
11	4	11
12	4	12
13	4	13
14	4	14
15	4	15
16	4	16
17	4	17
18	4	18
19	4	19
20	4	20
21	4	21
22	4	22
23	4	23
24	4	24
25	4	25
26	4	26
27	4	27
28	4	28
29	4	29
30	4	30
31	4	31
32	4	32
33	4	33
34	4	34
35	4	35
36	4	36
37	4	37
38	4	38
39	4	39
40	4	40
41	4	41
42	4	42
43	4	43
44	4	44
45	4	45
46	4	46
47	4	47
48	4	48
49	4	49
50	4	50
51	4	51
52	4	52
53	4	53
54	4	54
55	4	55
56	4	56
57	4	57
58	4	58
59	4	59
60	4	60
61	4	61
62	4	62
63	4	63
64	4	64
65	4	65
66	4	66
67	4	67
68	4	68
69	4	69
70	4	70
71	4	71
72	4	72
73	4	73
74	4	74
75	4	75
76	4	76
77	4	77
78	4	78
79	4	79
80	4	80
81	4	81
82	4	82
83	4	83
84	4	84
85	4	85
86	4	86
87	4	87
88	4	88
89	4	89
90	4	90
91	4	91
92	4	92
93	4	93
94	4	94
95	4	95
96	4	96
97	4	97
98	4	98
99	4	99
100	4	100
101	4	101
102	4	102
103	4	103
104	4	104
105	4	105
106	4	106
107	4	107
108	4	108
109	4	109
110	4	110
111	4	111
112	4	112
113	4	113
114	4	114
115	4	115
116	4	116
117	4	117
118	4	118
119	4	119
120	4	120
121	4	121
122	4	122
123	4	123
124	4	124
125	4	125
126	4	126
127	4	127
128	4	128
129	4	129
130	4	130
131	4	131
132	4	132
133	4	133
134	4	134
135	4	135
136	4	136
137	4	137
138	4	138
139	4	139
140	4	140
141	4	141
142	4	142
143	4	143
144	4	144
145	4	145
146	4	146
147	4	147
148	4	148
149	4	149
150	4	150
151	4	151
152	4	152
153	4	153
154	4	154
155	4	155
156	4	156
157	4	157
158	4	158
159	4	159
160	4	160
161	4	161
162	4	162
163	4	163
164	4	164
165	4	165
166	4	166
167	4	167
168	4	168
169	4	169
170	4	170
171	4	171
172	4	172
173	4	173
174	4	174
175	4	175
176	4	176
177	4	177
178	4	178
179	4	179
180	4	180
181	4	181
182	4	182
183	4	183
184	4	184
185	4	185
186	4	186
187	4	187
188	4	188
189	4	189
190	4	190
191	4	191
192	4	192
193	4	193
194	4	194
195	4	195
196	4	196
197	4	197
198	4	198
199	4	199
200	4	200
201	4	201
202	4	202
203	4	203
204	4	204
205	4	205
206	4	206
207	4	207
208	4	208
209	4	209
210	4	210
211	4	211
212	4	212
213	4	213
214	4	214
215	4	215
216	4	216
217	4	217
218	4	218
219	4	219
220	4	220
221	4	221
222	4	222
223	4	223
224	4	224
225	4	225
226	4	226
227	4	227
228	4	228
229	4	229
230	4	230
231	4	231
232	4	232
233	4	233
234	4	234
235	4	235
236	4	236
237	4	237
238	4	238
239	4	239
240	4	240
241	4	241
242	4	242
243	4	243
244	4	244
245	4	245
246	4	246
247	4	247
248	4	248
249	4	249
250	4	250
251	4	251
252	4	252
253	4	253
254	4	254
255	4	255
256	4	256
257	4	257
258	4	258
259	4	259
260	4	260
261	4	261
262	4	262
263	4	263
264	4	264
265	4	265
266	4	266
267	4	267
268	4	268
269	4	269
270	4	270
271	4	271
272	4	272
273	4	273
274	4	274
275	4	275
276	4	276
277	4	277
278	4	278
279	4	279
280	5	41
281	5	42
282	5	43
283	5	46
284	5	51
285	5	56
286	5	57
287	5	58
288	5	61
289	5	66
290	5	71
291	5	76
292	5	77
293	5	78
294	5	81
295	5	86
296	5	91
297	5	106
298	5	111
299	5	121
300	5	136
301	5	141
302	5	142
303	5	143
304	5	146
305	5	147
306	5	148
307	5	151
308	5	156
309	5	157
310	5	158
311	5	161
312	5	162
313	5	163
314	5	166
315	5	171
316	5	172
317	5	173
318	5	176
319	5	177
320	5	178
321	5	181
322	5	186
323	5	187
324	5	188
325	5	191
326	5	192
327	5	193
328	5	196
329	5	201
330	5	202
331	5	203
332	5	206
333	5	207
334	5	208
335	5	211
336	5	216
337	5	221
338	5	222
339	5	223
340	5	231
341	5	236
342	5	237
343	5	241
344	5	252
345	5	253
346	5	254
347	5	255
348	5	256
349	5	257
350	5	258
351	5	259
352	5	260
353	5	261
354	5	262
355	5	264
356	5	265
357	5	266
358	5	267
359	5	268
360	5	269
361	5	270
362	5	271
363	5	272
364	5	273
365	5	274
366	5	275
367	5	276
368	5	277
369	5	278
370	5	279
371	6	41
372	6	76
373	6	156
374	6	157
375	6	158
376	6	161
377	6	162
378	6	163
379	6	166
380	6	236
381	6	237
382	6	252
383	6	253
384	6	258
385	6	259
386	6	267
387	6	269
388	6	278
389	6	279
\.


--
-- TOC entry 5857 (class 0 OID 35975)
-- Dependencies: 232
-- Data for Name: sy07_doc_num; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sy07_doc_num (id, doc_name, prefix, next_no, step, status, created_by, created_at) FROM stdin;
\.


--
-- TOC entry 5963 (class 0 OID 38155)
-- Dependencies: 338
-- Data for Name: sy08_lkup_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sy08_lkup_config (id, lookup_code, table_name, key_field, desc_field, extra_field, display_title, filter_condition, col1_title, col2_title, col3_title, created_at, updated_at) FROM stdin;
1	stock	st01_mast	id	description	cat_id	Stock Items	\N	ID	Description	Category	2025-11-20 13:25:40.387971	2025-11-20 13:25:40.387971
2	stock_category	st02_cat	id	cat_desc		Stock Categories	\N	ID	Category		2025-11-20 13:25:40.387971	2025-11-20 13:25:40.387971
3	uom	st03_uom_master	id	uom_desc		Units of Measure	\N	ID	UOM		2025-11-20 13:25:40.387971	2025-11-20 13:25:40.387971
4	debtors	dl01_mast	id	name	phone	Debtors / Customers	\N	ID	Customer Name	Phone	2025-11-20 13:25:40.387971	2025-11-20 13:25:40.387971
5	creditors	cl01_mast	id	name	phone	Creditors / Suppliers	\N	ID	Supplier Name	Phone	2025-11-20 13:25:40.387971	2025-11-20 13:25:40.387971
6	warehouse	wh01_mast	id	wh_desc	location	Warehouses	\N	ID	Warehouse Name	Location	2025-11-20 13:25:40.387971	2025-11-20 13:25:40.387971
7	bin	wb01_mast	id	bin_desc	wh_id	Warehouse Bins	\N	ID	Bin	Warehouse	2025-11-20 13:25:40.387971	2025-11-20 13:25:40.387971
8	pu_ord	pu30_ord_hdr	id	supp_name	status	Purchase Orders	\N	PO Number	Supplier	Status	2025-11-20 13:30:25.431034	2025-11-20 13:30:25.431034
10	pu_inv	pu32_inv_hdr	id	supp_name	status	Supplier Invoices	\N	Invoice No	Supplier	Status	2025-11-20 13:30:25.431034	2025-11-20 13:30:25.431034
11	sa_quote	sa30_quo_hdr	id	customer	status	Sales Quotes	\N	Quote No	Customer	Status	2025-11-20 13:31:14.352643	2025-11-20 13:31:14.352643
12	sa_order	sa31_ord_hdr	id	customer	status	Sales Orders	\N	Order Number	Customer	Status	2025-11-20 13:31:14.352643	2025-11-20 13:31:14.352643
13	sa_inv	sa32_inv_hdr	id	customer	status	Sales Invoices	\N	Invoice No	Customer	Status	2025-11-20 13:31:14.352643	2025-11-20 13:31:14.352643
14	gl_accounts	gl01_acc	id	acc_desc	\N	GL Accounts	\N	ID	Account	Type	2025-11-20 13:32:08.127856	2025-11-20 13:32:08.127856
15	gl_journals	gl30_journal_hdr	id	doc_no	\N	GL Journals	\N	ID	Journal No	Period	2025-11-20 13:32:08.127856	2025-11-20 13:32:08.127856
9	pu_grn	pu31_grn_hdr	id	supp_name	status	Goods Received Notes	\N	GRN Number	Supplier	Status	2025-11-20 13:30:25.431034	2025-11-21 11:59:30.542
\.


--
-- TOC entry 5860 (class 0 OID 36006)
-- Dependencies: 235
-- Data for Name: sy40_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sy40_hist (id, entity, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5876 (class 0 OID 36152)
-- Dependencies: 251
-- Data for Name: wb01_mast; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wb01_mast (id, wb_code, wh_id, description, status, created_at, updated_at, deleted_at, created_by) FROM stdin;
\.


--
-- TOC entry 5885 (class 0 OID 36277)
-- Dependencies: 260
-- Data for Name: wb30_trf_hdr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wb30_trf_hdr (id, trans_no, wb_from, wb_to, trans_date, created_by, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5887 (class 0 OID 36303)
-- Dependencies: 262
-- Data for Name: wb31_trf_det; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wb31_trf_det (id, hdr_id, item_no, stock_id, qnty, batch_id, expiry_date) FROM stdin;
\.


--
-- TOC entry 5889 (class 0 OID 36323)
-- Dependencies: 264
-- Data for Name: wb40_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wb40_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5874 (class 0 OID 36136)
-- Dependencies: 249
-- Data for Name: wh01_mast; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wh01_mast (id, wh_code, wh_name, location, status, created_at, updated_at, deleted_at, created_by) FROM stdin;
3	WH3	Waterfront	Cape Town	active	2025-11-12 06:07:05.614	2025-11-19 10:31:52.211	\N	2
4	WH4	NPOS	NOOS	active	2025-11-14 14:54:28.802	2025-11-19 10:32:07.382	\N	2
1	WH1	DBN Warehouse	Durban	active	2025-11-12 04:56:15.401	2025-11-19 10:30:02.414	\N	2
2	WH2	JHB Warehouse	JHB	0	2025-11-12 05:14:03.862	2025-11-19 15:23:44.746	\N	2
\.


--
-- TOC entry 5947 (class 0 OID 37237)
-- Dependencies: 322
-- Data for Name: wh30_trans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wh30_trans (id, trans_date, trans_type, ref_no, source_module, source_doc_id, wh_id, wb_id, stock_id, qnty_in, qnty_out, run_qty, uom, unit_cost, ext_cost, remarks, status, created_by, created_at, updated_by, updated_at) FROM stdin;
\.


--
-- TOC entry 5951 (class 0 OID 37302)
-- Dependencies: 326
-- Data for Name: wh30_trf_hdr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wh30_trf_hdr (id, trans_no, from_wh_id, to_wh_id, from_wb_id, to_wb_id, trans_date, notes, status, created_by, created_at, updated_by, updated_at, deleted_at) FROM stdin;
\.


--
-- TOC entry 5953 (class 0 OID 37350)
-- Dependencies: 328
-- Data for Name: wh31_trf_det; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wh31_trf_det (id, hdr_id, item_no, stock_id, item_name, uom, from_wb_id, to_wb_id, batch_id, expiry_date, qnty, unit_cost, ext_cost, notes, status, created_at, created_by, updated_at, updated_by) FROM stdin;
\.


--
-- TOC entry 5949 (class 0 OID 37281)
-- Dependencies: 324
-- Data for Name: wh40_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wh40_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5955 (class 0 OID 37398)
-- Dependencies: 330
-- Data for Name: wh40_trf_hist; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wh40_trf_hist (id, ref_id, action, old_values, new_values, changed_by, changed_at) FROM stdin;
\.


--
-- TOC entry 5974 (class 0 OID 0)
-- Dependencies: 238
-- Name: cl01_mast_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cl01_mast_id_seq', 7, true);


--
-- TOC entry 5975 (class 0 OID 0)
-- Dependencies: 244
-- Name: cl30_trans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cl30_trans_id_seq', 16, true);


--
-- TOC entry 5976 (class 0 OID 0)
-- Dependencies: 246
-- Name: cl40_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cl40_hist_id_seq', 1, false);


--
-- TOC entry 5977 (class 0 OID 0)
-- Dependencies: 236
-- Name: dl01_mast_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dl01_mast_id_seq', 5, true);


--
-- TOC entry 5978 (class 0 OID 0)
-- Dependencies: 240
-- Name: dl30_trans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dl30_trans_id_seq', 1, false);


--
-- TOC entry 5979 (class 0 OID 0)
-- Dependencies: 242
-- Name: dl40_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dl40_hist_id_seq', 1, false);


--
-- TOC entry 5980 (class 0 OID 0)
-- Dependencies: 265
-- Name: gl01_acc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gl01_acc_id_seq', 1, false);


--
-- TOC entry 5981 (class 0 OID 0)
-- Dependencies: 267
-- Name: gl30_jnls_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gl30_jnls_id_seq', 1, false);


--
-- TOC entry 5982 (class 0 OID 0)
-- Dependencies: 269
-- Name: gl31_lines_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gl31_lines_id_seq', 1, false);


--
-- TOC entry 5983 (class 0 OID 0)
-- Dependencies: 271
-- Name: gl40_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gl40_hist_id_seq', 1, false);


--
-- TOC entry 5984 (class 0 OID 0)
-- Dependencies: 273
-- Name: payt30_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payt30_hdr_id_seq', 1, false);


--
-- TOC entry 5985 (class 0 OID 0)
-- Dependencies: 275
-- Name: payt31_trans_det_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payt31_trans_det_id_seq', 1, false);


--
-- TOC entry 5986 (class 0 OID 0)
-- Dependencies: 277
-- Name: payt40_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payt40_hist_id_seq', 1, false);


--
-- TOC entry 5987 (class 0 OID 0)
-- Dependencies: 281
-- Name: pu30_ord_det_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pu30_ord_det_id_seq', 38, true);


--
-- TOC entry 5988 (class 0 OID 0)
-- Dependencies: 279
-- Name: pu30_ord_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pu30_ord_hdr_id_seq', 149, true);


--
-- TOC entry 5989 (class 0 OID 0)
-- Dependencies: 283
-- Name: pu30_ord_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pu30_ord_hist_id_seq', 1, false);


--
-- TOC entry 5990 (class 0 OID 0)
-- Dependencies: 287
-- Name: pu31_grn_det_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pu31_grn_det_id_seq', 1, false);


--
-- TOC entry 5991 (class 0 OID 0)
-- Dependencies: 285
-- Name: pu31_grn_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pu31_grn_hdr_id_seq', 1, false);


--
-- TOC entry 5992 (class 0 OID 0)
-- Dependencies: 289
-- Name: pu31_grn_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pu31_grn_hist_id_seq', 1, false);


--
-- TOC entry 5993 (class 0 OID 0)
-- Dependencies: 293
-- Name: pu32_inv_det_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pu32_inv_det_id_seq', 1, false);


--
-- TOC entry 5994 (class 0 OID 0)
-- Dependencies: 291
-- Name: pu32_inv_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pu32_inv_hdr_id_seq', 1, false);


--
-- TOC entry 5995 (class 0 OID 0)
-- Dependencies: 295
-- Name: pu32_inv_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pu32_inv_hist_id_seq', 1, false);


--
-- TOC entry 5996 (class 0 OID 0)
-- Dependencies: 299
-- Name: sa30_quo_det_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa30_quo_det_id_seq', 1, false);


--
-- TOC entry 5997 (class 0 OID 0)
-- Dependencies: 297
-- Name: sa30_quo_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa30_quo_hdr_id_seq', 1, false);


--
-- TOC entry 5998 (class 0 OID 0)
-- Dependencies: 301
-- Name: sa30_quo_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa30_quo_hist_id_seq', 1, false);


--
-- TOC entry 5999 (class 0 OID 0)
-- Dependencies: 305
-- Name: sa31_ord_det_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa31_ord_det_id_seq', 1, false);


--
-- TOC entry 6000 (class 0 OID 0)
-- Dependencies: 303
-- Name: sa31_ord_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa31_ord_hdr_id_seq', 1, false);


--
-- TOC entry 6001 (class 0 OID 0)
-- Dependencies: 307
-- Name: sa31_ord_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa31_ord_hist_id_seq', 1, false);


--
-- TOC entry 6002 (class 0 OID 0)
-- Dependencies: 311
-- Name: sa32_inv_det_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa32_inv_det_id_seq', 1, false);


--
-- TOC entry 6003 (class 0 OID 0)
-- Dependencies: 309
-- Name: sa32_inv_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa32_inv_hdr_id_seq', 1, false);


--
-- TOC entry 6004 (class 0 OID 0)
-- Dependencies: 313
-- Name: sa32_inv_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa32_inv_hist_id_seq', 1, false);


--
-- TOC entry 6005 (class 0 OID 0)
-- Dependencies: 317
-- Name: sa33_crn_det_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa33_crn_det_id_seq', 1, false);


--
-- TOC entry 6006 (class 0 OID 0)
-- Dependencies: 315
-- Name: sa33_crn_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa33_crn_hdr_id_seq', 1, false);


--
-- TOC entry 6007 (class 0 OID 0)
-- Dependencies: 319
-- Name: sa33_crn_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sa33_crn_hist_id_seq', 1, false);


--
-- TOC entry 6008 (class 0 OID 0)
-- Dependencies: 254
-- Name: st01_mast_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.st01_mast_id_seq', 25, true);


--
-- TOC entry 6009 (class 0 OID 0)
-- Dependencies: 252
-- Name: st02_cat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.st02_cat_id_seq', 14, true);


--
-- TOC entry 6010 (class 0 OID 0)
-- Dependencies: 331
-- Name: st03_uom_master_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.st03_uom_master_id_seq', 12, true);


--
-- TOC entry 6011 (class 0 OID 0)
-- Dependencies: 333
-- Name: st04_stock_uom_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.st04_stock_uom_id_seq', 1, false);


--
-- TOC entry 6012 (class 0 OID 0)
-- Dependencies: 256
-- Name: st30_trans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.st30_trans_id_seq', 1, false);


--
-- TOC entry 6013 (class 0 OID 0)
-- Dependencies: 335
-- Name: st30_trans_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.st30_trans_id_seq1', 2, true);


--
-- TOC entry 6014 (class 0 OID 0)
-- Dependencies: 257
-- Name: st40_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.st40_hist_id_seq', 1, false);


--
-- TOC entry 6015 (class 0 OID 0)
-- Dependencies: 223
-- Name: sy00_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy00_user_id_seq', 27, true);


--
-- TOC entry 6016 (class 0 OID 0)
-- Dependencies: 225
-- Name: sy01_sess_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy01_sess_id_seq', 1, false);


--
-- TOC entry 6017 (class 0 OID 0)
-- Dependencies: 227
-- Name: sy02_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy02_logs_id_seq', 1, false);


--
-- TOC entry 6018 (class 0 OID 0)
-- Dependencies: 229
-- Name: sy03_sett_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy03_sett_id_seq', 6, true);


--
-- TOC entry 6019 (class 0 OID 0)
-- Dependencies: 217
-- Name: sy04_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy04_role_id_seq', 6, true);


--
-- TOC entry 6020 (class 0 OID 0)
-- Dependencies: 219
-- Name: sy05_perm_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy05_perm_id_seq', 558, true);


--
-- TOC entry 6021 (class 0 OID 0)
-- Dependencies: 221
-- Name: sy06_role_perm_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy06_role_perm_id_seq', 389, true);


--
-- TOC entry 6022 (class 0 OID 0)
-- Dependencies: 231
-- Name: sy07_doc_num_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy07_doc_num_id_seq', 1, false);


--
-- TOC entry 6023 (class 0 OID 0)
-- Dependencies: 233
-- Name: sy08_lkup_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy08_lkup_config_id_seq', 91, true);


--
-- TOC entry 6024 (class 0 OID 0)
-- Dependencies: 337
-- Name: sy08_lkup_config_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy08_lkup_config_id_seq1', 15, true);


--
-- TOC entry 6025 (class 0 OID 0)
-- Dependencies: 234
-- Name: sy40_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sy40_hist_id_seq', 1, false);


--
-- TOC entry 6026 (class 0 OID 0)
-- Dependencies: 250
-- Name: wb01_mast_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wb01_mast_id_seq', 2, true);


--
-- TOC entry 6027 (class 0 OID 0)
-- Dependencies: 259
-- Name: wb30_trf_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wb30_trf_hdr_id_seq', 1, false);


--
-- TOC entry 6028 (class 0 OID 0)
-- Dependencies: 261
-- Name: wb31_trf_det_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wb31_trf_det_id_seq', 1, false);


--
-- TOC entry 6029 (class 0 OID 0)
-- Dependencies: 263
-- Name: wb40_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wb40_hist_id_seq', 1, false);


--
-- TOC entry 6030 (class 0 OID 0)
-- Dependencies: 248
-- Name: wh01_mast_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wh01_mast_id_seq', 4, true);


--
-- TOC entry 6031 (class 0 OID 0)
-- Dependencies: 321
-- Name: wh30_trans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wh30_trans_id_seq', 1, false);


--
-- TOC entry 6032 (class 0 OID 0)
-- Dependencies: 325
-- Name: wh30_trf_hdr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wh30_trf_hdr_id_seq', 1, false);


--
-- TOC entry 6033 (class 0 OID 0)
-- Dependencies: 327
-- Name: wh31_trf_det_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wh31_trf_det_id_seq', 1, false);


--
-- TOC entry 6034 (class 0 OID 0)
-- Dependencies: 323
-- Name: wh40_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wh40_hist_id_seq', 1, false);


--
-- TOC entry 6035 (class 0 OID 0)
-- Dependencies: 329
-- Name: wh40_trf_hist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wh40_trf_hist_id_seq', 1, false);


--
-- TOC entry 5366 (class 2606 OID 36051)
-- Name: cl01_mast cl01_mast_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cl01_mast
    ADD CONSTRAINT cl01_mast_pkey PRIMARY KEY (id);


--
-- TOC entry 5373 (class 2606 OID 36109)
-- Name: cl30_trans cl30_trans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cl30_trans
    ADD CONSTRAINT cl30_trans_pkey PRIMARY KEY (id);


--
-- TOC entry 5376 (class 2606 OID 36124)
-- Name: cl40_hist cl40_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cl40_hist
    ADD CONSTRAINT cl40_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5364 (class 2606 OID 36034)
-- Name: dl01_mast dl01_mast_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dl01_mast
    ADD CONSTRAINT dl01_mast_pkey PRIMARY KEY (id);


--
-- TOC entry 5368 (class 2606 OID 36070)
-- Name: dl30_trans dl30_trans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dl30_trans
    ADD CONSTRAINT dl30_trans_pkey PRIMARY KEY (id);


--
-- TOC entry 5371 (class 2606 OID 36085)
-- Name: dl40_hist dl40_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dl40_hist
    ADD CONSTRAINT dl40_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5408 (class 2606 OID 36353)
-- Name: gl01_acc gl01_acc_acc_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl01_acc
    ADD CONSTRAINT gl01_acc_acc_code_key UNIQUE (acc_code);


--
-- TOC entry 5410 (class 2606 OID 36351)
-- Name: gl01_acc gl01_acc_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl01_acc
    ADD CONSTRAINT gl01_acc_pkey PRIMARY KEY (id);


--
-- TOC entry 5412 (class 2606 OID 36375)
-- Name: gl30_jnls gl30_jnls_jrn_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl30_jnls
    ADD CONSTRAINT gl30_jnls_jrn_no_key UNIQUE (jrn_no);


--
-- TOC entry 5414 (class 2606 OID 36373)
-- Name: gl30_jnls gl30_jnls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl30_jnls
    ADD CONSTRAINT gl30_jnls_pkey PRIMARY KEY (id);


--
-- TOC entry 5416 (class 2606 OID 36391)
-- Name: gl31_lines gl31_lines_jrn_id_line_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl31_lines
    ADD CONSTRAINT gl31_lines_jrn_id_line_no_key UNIQUE (jrn_id, line_no);


--
-- TOC entry 5418 (class 2606 OID 36389)
-- Name: gl31_lines gl31_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl31_lines
    ADD CONSTRAINT gl31_lines_pkey PRIMARY KEY (id);


--
-- TOC entry 5420 (class 2606 OID 36411)
-- Name: gl40_hist gl40_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl40_hist
    ADD CONSTRAINT gl40_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5422 (class 2606 OID 36436)
-- Name: payt30_hdr payt30_hdr_doc_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payt30_hdr
    ADD CONSTRAINT payt30_hdr_doc_no_key UNIQUE (doc_no);


--
-- TOC entry 5424 (class 2606 OID 36434)
-- Name: payt30_hdr payt30_hdr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payt30_hdr
    ADD CONSTRAINT payt30_hdr_pkey PRIMARY KEY (id);


--
-- TOC entry 5426 (class 2606 OID 36450)
-- Name: payt31_trans_det payt31_trans_det_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payt31_trans_det
    ADD CONSTRAINT payt31_trans_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5428 (class 2606 OID 36465)
-- Name: payt40_hist payt40_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payt40_hist
    ADD CONSTRAINT payt40_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5436 (class 2606 OID 36530)
-- Name: pu30_ord_det pu30_ord_det_hdr_id_line_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_det
    ADD CONSTRAINT pu30_ord_det_hdr_id_line_no_key UNIQUE (hdr_id, line_no);


--
-- TOC entry 5438 (class 2606 OID 36528)
-- Name: pu30_ord_det pu30_ord_det_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_det
    ADD CONSTRAINT pu30_ord_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5431 (class 2606 OID 36493)
-- Name: pu30_ord_hdr pu30_ord_hdr_doc_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_hdr
    ADD CONSTRAINT pu30_ord_hdr_doc_no_key UNIQUE (doc_no);


--
-- TOC entry 5433 (class 2606 OID 36491)
-- Name: pu30_ord_hdr pu30_ord_hdr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_hdr
    ADD CONSTRAINT pu30_ord_hdr_pkey PRIMARY KEY (id);


--
-- TOC entry 5440 (class 2606 OID 36570)
-- Name: pu30_ord_hist pu30_ord_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_hist
    ADD CONSTRAINT pu30_ord_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5448 (class 2606 OID 36639)
-- Name: pu31_grn_det pu31_grn_det_hdr_id_line_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_det
    ADD CONSTRAINT pu31_grn_det_hdr_id_line_no_key UNIQUE (hdr_id, line_no);


--
-- TOC entry 5450 (class 2606 OID 36637)
-- Name: pu31_grn_det pu31_grn_det_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_det
    ADD CONSTRAINT pu31_grn_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5443 (class 2606 OID 37987)
-- Name: pu31_grn_hdr pu31_grn_hdr_doc_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_hdr
    ADD CONSTRAINT pu31_grn_hdr_doc_no_key UNIQUE (doc_no);


--
-- TOC entry 5445 (class 2606 OID 36595)
-- Name: pu31_grn_hdr pu31_grn_hdr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_hdr
    ADD CONSTRAINT pu31_grn_hdr_pkey PRIMARY KEY (id);


--
-- TOC entry 5452 (class 2606 OID 36679)
-- Name: pu31_grn_hist pu31_grn_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_hist
    ADD CONSTRAINT pu31_grn_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5460 (class 2606 OID 36744)
-- Name: pu32_inv_det pu32_inv_det_hdr_id_line_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_det
    ADD CONSTRAINT pu32_inv_det_hdr_id_line_no_key UNIQUE (hdr_id, line_no);


--
-- TOC entry 5462 (class 2606 OID 36742)
-- Name: pu32_inv_det pu32_inv_det_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_det
    ADD CONSTRAINT pu32_inv_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5455 (class 2606 OID 36707)
-- Name: pu32_inv_hdr pu32_inv_hdr_doc_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_hdr
    ADD CONSTRAINT pu32_inv_hdr_doc_no_key UNIQUE (doc_no);


--
-- TOC entry 5457 (class 2606 OID 36705)
-- Name: pu32_inv_hdr pu32_inv_hdr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_hdr
    ADD CONSTRAINT pu32_inv_hdr_pkey PRIMARY KEY (id);


--
-- TOC entry 5464 (class 2606 OID 36784)
-- Name: pu32_inv_hist pu32_inv_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_hist
    ADD CONSTRAINT pu32_inv_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5472 (class 2606 OID 36849)
-- Name: sa30_quo_det sa30_quo_det_hdr_id_line_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_det
    ADD CONSTRAINT sa30_quo_det_hdr_id_line_no_key UNIQUE (hdr_id, line_no);


--
-- TOC entry 5474 (class 2606 OID 36847)
-- Name: sa30_quo_det sa30_quo_det_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_det
    ADD CONSTRAINT sa30_quo_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5467 (class 2606 OID 36812)
-- Name: sa30_quo_hdr sa30_quo_hdr_doc_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_hdr
    ADD CONSTRAINT sa30_quo_hdr_doc_no_key UNIQUE (doc_no);


--
-- TOC entry 5469 (class 2606 OID 36810)
-- Name: sa30_quo_hdr sa30_quo_hdr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_hdr
    ADD CONSTRAINT sa30_quo_hdr_pkey PRIMARY KEY (id);


--
-- TOC entry 5476 (class 2606 OID 36889)
-- Name: sa30_quo_hist sa30_quo_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_hist
    ADD CONSTRAINT sa30_quo_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5484 (class 2606 OID 36954)
-- Name: sa31_ord_det sa31_ord_det_hdr_id_line_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_det
    ADD CONSTRAINT sa31_ord_det_hdr_id_line_no_key UNIQUE (hdr_id, line_no);


--
-- TOC entry 5486 (class 2606 OID 36952)
-- Name: sa31_ord_det sa31_ord_det_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_det
    ADD CONSTRAINT sa31_ord_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5479 (class 2606 OID 36917)
-- Name: sa31_ord_hdr sa31_ord_hdr_doc_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_hdr
    ADD CONSTRAINT sa31_ord_hdr_doc_no_key UNIQUE (doc_no);


--
-- TOC entry 5481 (class 2606 OID 36915)
-- Name: sa31_ord_hdr sa31_ord_hdr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_hdr
    ADD CONSTRAINT sa31_ord_hdr_pkey PRIMARY KEY (id);


--
-- TOC entry 5488 (class 2606 OID 36994)
-- Name: sa31_ord_hist sa31_ord_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_hist
    ADD CONSTRAINT sa31_ord_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5496 (class 2606 OID 37059)
-- Name: sa32_inv_det sa32_inv_det_hdr_id_line_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_det
    ADD CONSTRAINT sa32_inv_det_hdr_id_line_no_key UNIQUE (hdr_id, line_no);


--
-- TOC entry 5498 (class 2606 OID 37057)
-- Name: sa32_inv_det sa32_inv_det_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_det
    ADD CONSTRAINT sa32_inv_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5491 (class 2606 OID 37022)
-- Name: sa32_inv_hdr sa32_inv_hdr_doc_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_hdr
    ADD CONSTRAINT sa32_inv_hdr_doc_no_key UNIQUE (doc_no);


--
-- TOC entry 5493 (class 2606 OID 37020)
-- Name: sa32_inv_hdr sa32_inv_hdr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_hdr
    ADD CONSTRAINT sa32_inv_hdr_pkey PRIMARY KEY (id);


--
-- TOC entry 5500 (class 2606 OID 37099)
-- Name: sa32_inv_hist sa32_inv_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_hist
    ADD CONSTRAINT sa32_inv_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5508 (class 2606 OID 37164)
-- Name: sa33_crn_det sa33_crn_det_hdr_id_line_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_det
    ADD CONSTRAINT sa33_crn_det_hdr_id_line_no_key UNIQUE (hdr_id, line_no);


--
-- TOC entry 5510 (class 2606 OID 37162)
-- Name: sa33_crn_det sa33_crn_det_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_det
    ADD CONSTRAINT sa33_crn_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5503 (class 2606 OID 37127)
-- Name: sa33_crn_hdr sa33_crn_hdr_doc_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_hdr
    ADD CONSTRAINT sa33_crn_hdr_doc_no_key UNIQUE (doc_no);


--
-- TOC entry 5505 (class 2606 OID 37125)
-- Name: sa33_crn_hdr sa33_crn_hdr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_hdr
    ADD CONSTRAINT sa33_crn_hdr_pkey PRIMARY KEY (id);


--
-- TOC entry 5512 (class 2606 OID 37204)
-- Name: sa33_crn_hist sa33_crn_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_hist
    ADD CONSTRAINT sa33_crn_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5392 (class 2606 OID 36204)
-- Name: st01_mast st01_mast_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st01_mast
    ADD CONSTRAINT st01_mast_pkey PRIMARY KEY (id);


--
-- TOC entry 5394 (class 2606 OID 36206)
-- Name: st01_mast st01_mast_stock_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st01_mast
    ADD CONSTRAINT st01_mast_stock_code_key UNIQUE (stock_code);


--
-- TOC entry 5387 (class 2606 OID 36182)
-- Name: st02_cat st02_cat_cat_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st02_cat
    ADD CONSTRAINT st02_cat_cat_code_key UNIQUE (cat_code);


--
-- TOC entry 5389 (class 2606 OID 36180)
-- Name: st02_cat st02_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st02_cat
    ADD CONSTRAINT st02_cat_pkey PRIMARY KEY (id);


--
-- TOC entry 5541 (class 2606 OID 37857)
-- Name: st03_uom_master st03_uom_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st03_uom_master
    ADD CONSTRAINT st03_uom_master_pkey PRIMARY KEY (id);


--
-- TOC entry 5543 (class 2606 OID 37859)
-- Name: st03_uom_master st03_uom_master_uom_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st03_uom_master
    ADD CONSTRAINT st03_uom_master_uom_code_key UNIQUE (uom_code);


--
-- TOC entry 5547 (class 2606 OID 37929)
-- Name: st04_stock_uom st04_stock_uom_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st04_stock_uom
    ADD CONSTRAINT st04_stock_uom_pkey PRIMARY KEY (id);


--
-- TOC entry 5549 (class 2606 OID 37931)
-- Name: st04_stock_uom st04_stock_uom_stock_id_uom_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st04_stock_uom
    ADD CONSTRAINT st04_stock_uom_stock_id_uom_id_key UNIQUE (stock_id, uom_id);


--
-- TOC entry 5552 (class 2606 OID 37979)
-- Name: st30_trans st30_trans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st30_trans
    ADD CONSTRAINT st30_trans_pkey PRIMARY KEY (id);


--
-- TOC entry 5396 (class 2606 OID 36265)
-- Name: st40_hist st40_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st40_hist
    ADD CONSTRAINT st40_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5346 (class 2606 OID 35926)
-- Name: sy00_user sy00_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy00_user
    ADD CONSTRAINT sy00_user_pkey PRIMARY KEY (id);


--
-- TOC entry 5348 (class 2606 OID 35928)
-- Name: sy00_user sy00_user_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy00_user
    ADD CONSTRAINT sy00_user_username_key UNIQUE (username);


--
-- TOC entry 5350 (class 2606 OID 35941)
-- Name: sy01_sess sy01_sess_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy01_sess
    ADD CONSTRAINT sy01_sess_pkey PRIMARY KEY (id);


--
-- TOC entry 5352 (class 2606 OID 35956)
-- Name: sy02_logs sy02_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy02_logs
    ADD CONSTRAINT sy02_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5354 (class 2606 OID 35971)
-- Name: sy03_sett sy03_sett_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy03_sett
    ADD CONSTRAINT sy03_sett_pkey PRIMARY KEY (id);


--
-- TOC entry 5356 (class 2606 OID 35973)
-- Name: sy03_sett sy03_sett_sett_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy03_sett
    ADD CONSTRAINT sy03_sett_sett_key_key UNIQUE (sett_key);


--
-- TOC entry 5334 (class 2606 OID 35883)
-- Name: sy04_role sy04_role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy04_role
    ADD CONSTRAINT sy04_role_pkey PRIMARY KEY (id);


--
-- TOC entry 5336 (class 2606 OID 35885)
-- Name: sy04_role sy04_role_role_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy04_role
    ADD CONSTRAINT sy04_role_role_name_key UNIQUE (role_name);


--
-- TOC entry 5338 (class 2606 OID 35896)
-- Name: sy05_perm sy05_perm_perm_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy05_perm
    ADD CONSTRAINT sy05_perm_perm_name_key UNIQUE (perm_name);


--
-- TOC entry 5340 (class 2606 OID 35894)
-- Name: sy05_perm sy05_perm_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy05_perm
    ADD CONSTRAINT sy05_perm_pkey PRIMARY KEY (id);


--
-- TOC entry 5342 (class 2606 OID 35903)
-- Name: sy06_role_perm sy06_role_perm_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy06_role_perm
    ADD CONSTRAINT sy06_role_perm_pkey PRIMARY KEY (id);


--
-- TOC entry 5344 (class 2606 OID 35905)
-- Name: sy06_role_perm sy06_role_perm_role_id_perm_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy06_role_perm
    ADD CONSTRAINT sy06_role_perm_role_id_perm_id_key UNIQUE (role_id, perm_id);


--
-- TOC entry 5358 (class 2606 OID 35986)
-- Name: sy07_doc_num sy07_doc_num_doc_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy07_doc_num
    ADD CONSTRAINT sy07_doc_num_doc_name_key UNIQUE (doc_name);


--
-- TOC entry 5360 (class 2606 OID 35984)
-- Name: sy07_doc_num sy07_doc_num_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy07_doc_num
    ADD CONSTRAINT sy07_doc_num_pkey PRIMARY KEY (id);


--
-- TOC entry 5555 (class 2606 OID 38164)
-- Name: sy08_lkup_config sy08_lkup_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy08_lkup_config
    ADD CONSTRAINT sy08_lkup_config_pkey PRIMARY KEY (id);


--
-- TOC entry 5362 (class 2606 OID 36014)
-- Name: sy40_hist sy40_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy40_hist
    ADD CONSTRAINT sy40_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5383 (class 2606 OID 36159)
-- Name: wb01_mast wb01_mast_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb01_mast
    ADD CONSTRAINT wb01_mast_pkey PRIMARY KEY (id);


--
-- TOC entry 5385 (class 2606 OID 36161)
-- Name: wb01_mast wb01_mast_wh_id_wb_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb01_mast
    ADD CONSTRAINT wb01_mast_wh_id_wb_code_key UNIQUE (wh_id, wb_code);


--
-- TOC entry 5398 (class 2606 OID 36284)
-- Name: wb30_trf_hdr wb30_trf_hdr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb30_trf_hdr
    ADD CONSTRAINT wb30_trf_hdr_pkey PRIMARY KEY (id);


--
-- TOC entry 5400 (class 2606 OID 36286)
-- Name: wb30_trf_hdr wb30_trf_hdr_trans_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb30_trf_hdr
    ADD CONSTRAINT wb30_trf_hdr_trans_no_key UNIQUE (trans_no);


--
-- TOC entry 5402 (class 2606 OID 36311)
-- Name: wb31_trf_det wb31_trf_det_hdr_id_item_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb31_trf_det
    ADD CONSTRAINT wb31_trf_det_hdr_id_item_no_key UNIQUE (hdr_id, item_no);


--
-- TOC entry 5404 (class 2606 OID 36309)
-- Name: wb31_trf_det wb31_trf_det_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb31_trf_det
    ADD CONSTRAINT wb31_trf_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5406 (class 2606 OID 36331)
-- Name: wb40_hist wb40_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb40_hist
    ADD CONSTRAINT wb40_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5378 (class 2606 OID 36143)
-- Name: wh01_mast wh01_mast_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh01_mast
    ADD CONSTRAINT wh01_mast_pkey PRIMARY KEY (id);


--
-- TOC entry 5380 (class 2606 OID 36145)
-- Name: wh01_mast wh01_mast_wh_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh01_mast
    ADD CONSTRAINT wh01_mast_wh_code_key UNIQUE (wh_code);


--
-- TOC entry 5519 (class 2606 OID 37249)
-- Name: wh30_trans wh30_trans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trans
    ADD CONSTRAINT wh30_trans_pkey PRIMARY KEY (id);


--
-- TOC entry 5528 (class 2606 OID 37312)
-- Name: wh30_trf_hdr wh30_trf_hdr_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trf_hdr
    ADD CONSTRAINT wh30_trf_hdr_pkey PRIMARY KEY (id);


--
-- TOC entry 5530 (class 2606 OID 37314)
-- Name: wh30_trf_hdr wh30_trf_hdr_trans_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trf_hdr
    ADD CONSTRAINT wh30_trf_hdr_trans_no_key UNIQUE (trans_no);


--
-- TOC entry 5534 (class 2606 OID 37364)
-- Name: wh31_trf_det wh31_trf_det_hdr_id_item_no_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh31_trf_det
    ADD CONSTRAINT wh31_trf_det_hdr_id_item_no_key UNIQUE (hdr_id, item_no);


--
-- TOC entry 5536 (class 2606 OID 37362)
-- Name: wh31_trf_det wh31_trf_det_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh31_trf_det
    ADD CONSTRAINT wh31_trf_det_pkey PRIMARY KEY (id);


--
-- TOC entry 5522 (class 2606 OID 37289)
-- Name: wh40_hist wh40_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh40_hist
    ADD CONSTRAINT wh40_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5539 (class 2606 OID 37406)
-- Name: wh40_trf_hist wh40_trf_hist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh40_trf_hist
    ADD CONSTRAINT wh40_trf_hist_pkey PRIMARY KEY (id);


--
-- TOC entry 5374 (class 1259 OID 37216)
-- Name: idx_cl30_supp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cl30_supp ON public.cl30_trans USING btree (supp_id);


--
-- TOC entry 5369 (class 1259 OID 37215)
-- Name: idx_dl30_cust; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dl30_cust ON public.dl30_trans USING btree (cust_id);


--
-- TOC entry 5434 (class 1259 OID 37222)
-- Name: idx_pu30_det_hdr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pu30_det_hdr ON public.pu30_ord_det USING btree (hdr_id);


--
-- TOC entry 5429 (class 1259 OID 37221)
-- Name: idx_pu30_hdr_supp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pu30_hdr_supp ON public.pu30_ord_hdr USING btree (supp_id);


--
-- TOC entry 5446 (class 1259 OID 37224)
-- Name: idx_pu31_det_hdr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pu31_det_hdr ON public.pu31_grn_det USING btree (hdr_id);


--
-- TOC entry 5441 (class 1259 OID 37223)
-- Name: idx_pu31_hdr_supp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pu31_hdr_supp ON public.pu31_grn_hdr USING btree (supp_id);


--
-- TOC entry 5458 (class 1259 OID 37226)
-- Name: idx_pu32_det_hdr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pu32_det_hdr ON public.pu32_inv_det USING btree (hdr_id);


--
-- TOC entry 5453 (class 1259 OID 37225)
-- Name: idx_pu32_hdr_supp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pu32_hdr_supp ON public.pu32_inv_hdr USING btree (supp_id);


--
-- TOC entry 5470 (class 1259 OID 37228)
-- Name: idx_sa30_det_hdr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sa30_det_hdr ON public.sa30_quo_det USING btree (hdr_id);


--
-- TOC entry 5465 (class 1259 OID 37227)
-- Name: idx_sa30_hdr_cust; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sa30_hdr_cust ON public.sa30_quo_hdr USING btree (cust_id);


--
-- TOC entry 5482 (class 1259 OID 37230)
-- Name: idx_sa31_det_hdr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sa31_det_hdr ON public.sa31_ord_det USING btree (hdr_id);


--
-- TOC entry 5477 (class 1259 OID 37229)
-- Name: idx_sa31_hdr_cust; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sa31_hdr_cust ON public.sa31_ord_hdr USING btree (cust_id);


--
-- TOC entry 5494 (class 1259 OID 37232)
-- Name: idx_sa32_det_hdr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sa32_det_hdr ON public.sa32_inv_det USING btree (hdr_id);


--
-- TOC entry 5489 (class 1259 OID 37231)
-- Name: idx_sa32_hdr_cust; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sa32_hdr_cust ON public.sa32_inv_hdr USING btree (cust_id);


--
-- TOC entry 5506 (class 1259 OID 37234)
-- Name: idx_sa33_det_hdr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sa33_det_hdr ON public.sa33_crn_det USING btree (hdr_id);


--
-- TOC entry 5501 (class 1259 OID 37233)
-- Name: idx_sa33_hdr_cust; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sa33_hdr_cust ON public.sa33_crn_hdr USING btree (cust_id);


--
-- TOC entry 5390 (class 1259 OID 37217)
-- Name: idx_st01_cat; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_st01_cat ON public.st01_mast USING btree (category_id);


--
-- TOC entry 5544 (class 1259 OID 37942)
-- Name: idx_stock_uom_stock; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stock_uom_stock ON public.st04_stock_uom USING btree (stock_id);


--
-- TOC entry 5545 (class 1259 OID 37943)
-- Name: idx_stock_uom_uom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stock_uom_uom ON public.st04_stock_uom USING btree (uom_id);


--
-- TOC entry 5381 (class 1259 OID 37220)
-- Name: idx_wb_wh; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wb_wh ON public.wb01_mast USING btree (wh_id);


--
-- TOC entry 5513 (class 1259 OID 37275)
-- Name: idx_wh30_trans_dt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh30_trans_dt ON public.wh30_trans USING btree (trans_date);


--
-- TOC entry 5514 (class 1259 OID 37278)
-- Name: idx_wh30_trans_stock; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh30_trans_stock ON public.wh30_trans USING btree (stock_id);


--
-- TOC entry 5515 (class 1259 OID 37279)
-- Name: idx_wh30_trans_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh30_trans_type ON public.wh30_trans USING btree (trans_type);


--
-- TOC entry 5516 (class 1259 OID 37277)
-- Name: idx_wh30_trans_wb; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh30_trans_wb ON public.wh30_trans USING btree (wb_id);


--
-- TOC entry 5517 (class 1259 OID 37276)
-- Name: idx_wh30_trans_wh; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh30_trans_wh ON public.wh30_trans USING btree (wh_id);


--
-- TOC entry 5523 (class 1259 OID 37345)
-- Name: idx_wh30_trf_hdr_dt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh30_trf_hdr_dt ON public.wh30_trf_hdr USING btree (trans_date);


--
-- TOC entry 5524 (class 1259 OID 37346)
-- Name: idx_wh30_trf_hdr_from; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh30_trf_hdr_from ON public.wh30_trf_hdr USING btree (from_wh_id);


--
-- TOC entry 5525 (class 1259 OID 37348)
-- Name: idx_wh30_trf_hdr_stat; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh30_trf_hdr_stat ON public.wh30_trf_hdr USING btree (status);


--
-- TOC entry 5526 (class 1259 OID 37347)
-- Name: idx_wh30_trf_hdr_to; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh30_trf_hdr_to ON public.wh30_trf_hdr USING btree (to_wh_id);


--
-- TOC entry 5531 (class 1259 OID 37395)
-- Name: idx_wh31_trf_det_hdr; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh31_trf_det_hdr ON public.wh31_trf_det USING btree (hdr_id);


--
-- TOC entry 5532 (class 1259 OID 37396)
-- Name: idx_wh31_trf_det_stock; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh31_trf_det_stock ON public.wh31_trf_det USING btree (stock_id);


--
-- TOC entry 5520 (class 1259 OID 37300)
-- Name: idx_wh40_hist_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh40_hist_ref ON public.wh40_hist USING btree (ref_id);


--
-- TOC entry 5537 (class 1259 OID 37417)
-- Name: idx_wh40_trf_hist_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wh40_trf_hist_ref ON public.wh40_trf_hist USING btree (ref_id);


--
-- TOC entry 5550 (class 1259 OID 37985)
-- Name: st30_trans_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX st30_trans_idx ON public.st30_trans USING btree (stock_id, trans_date);


--
-- TOC entry 5553 (class 1259 OID 38165)
-- Name: sy08_lkup_code_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX sy08_lkup_code_idx ON public.sy08_lkup_config USING btree (lookup_code);


--
-- TOC entry 5564 (class 2606 OID 36052)
-- Name: cl01_mast cl01_mast_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cl01_mast
    ADD CONSTRAINT cl01_mast_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5568 (class 2606 OID 36110)
-- Name: cl30_trans cl30_trans_supp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cl30_trans
    ADD CONSTRAINT cl30_trans_supp_id_fkey FOREIGN KEY (supp_id) REFERENCES public.cl01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5569 (class 2606 OID 36130)
-- Name: cl40_hist cl40_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cl40_hist
    ADD CONSTRAINT cl40_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5570 (class 2606 OID 36125)
-- Name: cl40_hist cl40_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cl40_hist
    ADD CONSTRAINT cl40_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.cl01_mast(id) ON DELETE CASCADE;


--
-- TOC entry 5563 (class 2606 OID 36035)
-- Name: dl01_mast dl01_mast_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dl01_mast
    ADD CONSTRAINT dl01_mast_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5565 (class 2606 OID 36071)
-- Name: dl30_trans dl30_trans_cust_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dl30_trans
    ADD CONSTRAINT dl30_trans_cust_id_fkey FOREIGN KEY (cust_id) REFERENCES public.dl01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5566 (class 2606 OID 36091)
-- Name: dl40_hist dl40_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dl40_hist
    ADD CONSTRAINT dl40_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5567 (class 2606 OID 36086)
-- Name: dl40_hist dl40_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dl40_hist
    ADD CONSTRAINT dl40_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.dl01_mast(id) ON DELETE CASCADE;


--
-- TOC entry 5586 (class 2606 OID 36359)
-- Name: gl01_acc gl01_acc_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl01_acc
    ADD CONSTRAINT gl01_acc_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5587 (class 2606 OID 36354)
-- Name: gl01_acc gl01_acc_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl01_acc
    ADD CONSTRAINT gl01_acc_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.gl01_acc(id) ON DELETE SET NULL;


--
-- TOC entry 5588 (class 2606 OID 36376)
-- Name: gl30_jnls gl30_jnls_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl30_jnls
    ADD CONSTRAINT gl30_jnls_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5589 (class 2606 OID 36397)
-- Name: gl31_lines gl31_lines_acc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl31_lines
    ADD CONSTRAINT gl31_lines_acc_id_fkey FOREIGN KEY (acc_id) REFERENCES public.gl01_acc(id) ON DELETE RESTRICT;


--
-- TOC entry 5590 (class 2606 OID 36392)
-- Name: gl31_lines gl31_lines_jrn_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl31_lines
    ADD CONSTRAINT gl31_lines_jrn_id_fkey FOREIGN KEY (jrn_id) REFERENCES public.gl30_jnls(id) ON DELETE CASCADE;


--
-- TOC entry 5591 (class 2606 OID 36417)
-- Name: gl40_hist gl40_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl40_hist
    ADD CONSTRAINT gl40_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5592 (class 2606 OID 36412)
-- Name: gl40_hist gl40_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gl40_hist
    ADD CONSTRAINT gl40_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.gl30_jnls(id) ON DELETE CASCADE;


--
-- TOC entry 5593 (class 2606 OID 36437)
-- Name: payt30_hdr payt30_hdr_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payt30_hdr
    ADD CONSTRAINT payt30_hdr_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5594 (class 2606 OID 36451)
-- Name: payt31_trans_det payt31_trans_det_hdr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payt31_trans_det
    ADD CONSTRAINT payt31_trans_det_hdr_id_fkey FOREIGN KEY (hdr_id) REFERENCES public.payt30_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5595 (class 2606 OID 36471)
-- Name: payt40_hist payt40_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payt40_hist
    ADD CONSTRAINT payt40_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5596 (class 2606 OID 36466)
-- Name: payt40_hist payt40_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payt40_hist
    ADD CONSTRAINT payt40_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.payt30_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5600 (class 2606 OID 36551)
-- Name: pu30_ord_det pu30_ord_det_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_det
    ADD CONSTRAINT pu30_ord_det_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5601 (class 2606 OID 36531)
-- Name: pu30_ord_det pu30_ord_det_hdr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_det
    ADD CONSTRAINT pu30_ord_det_hdr_id_fkey FOREIGN KEY (hdr_id) REFERENCES public.pu30_ord_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5602 (class 2606 OID 36536)
-- Name: pu30_ord_det pu30_ord_det_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_det
    ADD CONSTRAINT pu30_ord_det_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5603 (class 2606 OID 36556)
-- Name: pu30_ord_det pu30_ord_det_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_det
    ADD CONSTRAINT pu30_ord_det_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5597 (class 2606 OID 36499)
-- Name: pu30_ord_hdr pu30_ord_hdr_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_hdr
    ADD CONSTRAINT pu30_ord_hdr_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5598 (class 2606 OID 36494)
-- Name: pu30_ord_hdr pu30_ord_hdr_supp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_hdr
    ADD CONSTRAINT pu30_ord_hdr_supp_id_fkey FOREIGN KEY (supp_id) REFERENCES public.cl01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5599 (class 2606 OID 36504)
-- Name: pu30_ord_hdr pu30_ord_hdr_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_hdr
    ADD CONSTRAINT pu30_ord_hdr_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5604 (class 2606 OID 36576)
-- Name: pu30_ord_hist pu30_ord_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_hist
    ADD CONSTRAINT pu30_ord_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5605 (class 2606 OID 36571)
-- Name: pu30_ord_hist pu30_ord_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu30_ord_hist
    ADD CONSTRAINT pu30_ord_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.pu30_ord_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5610 (class 2606 OID 36660)
-- Name: pu31_grn_det pu31_grn_det_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_det
    ADD CONSTRAINT pu31_grn_det_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5611 (class 2606 OID 36640)
-- Name: pu31_grn_det pu31_grn_det_hdr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_det
    ADD CONSTRAINT pu31_grn_det_hdr_id_fkey FOREIGN KEY (hdr_id) REFERENCES public.pu31_grn_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5612 (class 2606 OID 36645)
-- Name: pu31_grn_det pu31_grn_det_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_det
    ADD CONSTRAINT pu31_grn_det_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5613 (class 2606 OID 36665)
-- Name: pu31_grn_det pu31_grn_det_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_det
    ADD CONSTRAINT pu31_grn_det_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5614 (class 2606 OID 36655)
-- Name: pu31_grn_det pu31_grn_det_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_det
    ADD CONSTRAINT pu31_grn_det_wb_id_fkey FOREIGN KEY (wb_id) REFERENCES public.wb01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5615 (class 2606 OID 36650)
-- Name: pu31_grn_det pu31_grn_det_wh_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_det
    ADD CONSTRAINT pu31_grn_det_wh_id_fkey FOREIGN KEY (wh_id) REFERENCES public.wh01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5606 (class 2606 OID 36608)
-- Name: pu31_grn_hdr pu31_grn_hdr_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_hdr
    ADD CONSTRAINT pu31_grn_hdr_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5607 (class 2606 OID 36603)
-- Name: pu31_grn_hdr pu31_grn_hdr_received_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_hdr
    ADD CONSTRAINT pu31_grn_hdr_received_by_fkey FOREIGN KEY (received_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5608 (class 2606 OID 36598)
-- Name: pu31_grn_hdr pu31_grn_hdr_supp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_hdr
    ADD CONSTRAINT pu31_grn_hdr_supp_id_fkey FOREIGN KEY (supp_id) REFERENCES public.cl01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5609 (class 2606 OID 36613)
-- Name: pu31_grn_hdr pu31_grn_hdr_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_hdr
    ADD CONSTRAINT pu31_grn_hdr_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5616 (class 2606 OID 36685)
-- Name: pu31_grn_hist pu31_grn_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_hist
    ADD CONSTRAINT pu31_grn_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5617 (class 2606 OID 36680)
-- Name: pu31_grn_hist pu31_grn_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu31_grn_hist
    ADD CONSTRAINT pu31_grn_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.pu31_grn_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5621 (class 2606 OID 36765)
-- Name: pu32_inv_det pu32_inv_det_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_det
    ADD CONSTRAINT pu32_inv_det_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5622 (class 2606 OID 36745)
-- Name: pu32_inv_det pu32_inv_det_hdr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_det
    ADD CONSTRAINT pu32_inv_det_hdr_id_fkey FOREIGN KEY (hdr_id) REFERENCES public.pu32_inv_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5623 (class 2606 OID 36750)
-- Name: pu32_inv_det pu32_inv_det_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_det
    ADD CONSTRAINT pu32_inv_det_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5624 (class 2606 OID 36770)
-- Name: pu32_inv_det pu32_inv_det_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_det
    ADD CONSTRAINT pu32_inv_det_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5625 (class 2606 OID 36760)
-- Name: pu32_inv_det pu32_inv_det_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_det
    ADD CONSTRAINT pu32_inv_det_wb_id_fkey FOREIGN KEY (wb_id) REFERENCES public.wb01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5626 (class 2606 OID 36755)
-- Name: pu32_inv_det pu32_inv_det_wh_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_det
    ADD CONSTRAINT pu32_inv_det_wh_id_fkey FOREIGN KEY (wh_id) REFERENCES public.wh01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5618 (class 2606 OID 36713)
-- Name: pu32_inv_hdr pu32_inv_hdr_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_hdr
    ADD CONSTRAINT pu32_inv_hdr_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5619 (class 2606 OID 36708)
-- Name: pu32_inv_hdr pu32_inv_hdr_supp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_hdr
    ADD CONSTRAINT pu32_inv_hdr_supp_id_fkey FOREIGN KEY (supp_id) REFERENCES public.cl01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5620 (class 2606 OID 36718)
-- Name: pu32_inv_hdr pu32_inv_hdr_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_hdr
    ADD CONSTRAINT pu32_inv_hdr_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5627 (class 2606 OID 36790)
-- Name: pu32_inv_hist pu32_inv_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_hist
    ADD CONSTRAINT pu32_inv_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5628 (class 2606 OID 36785)
-- Name: pu32_inv_hist pu32_inv_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pu32_inv_hist
    ADD CONSTRAINT pu32_inv_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.pu32_inv_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5632 (class 2606 OID 36870)
-- Name: sa30_quo_det sa30_quo_det_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_det
    ADD CONSTRAINT sa30_quo_det_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5633 (class 2606 OID 36850)
-- Name: sa30_quo_det sa30_quo_det_hdr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_det
    ADD CONSTRAINT sa30_quo_det_hdr_id_fkey FOREIGN KEY (hdr_id) REFERENCES public.sa30_quo_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5634 (class 2606 OID 36855)
-- Name: sa30_quo_det sa30_quo_det_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_det
    ADD CONSTRAINT sa30_quo_det_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5635 (class 2606 OID 36875)
-- Name: sa30_quo_det sa30_quo_det_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_det
    ADD CONSTRAINT sa30_quo_det_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5636 (class 2606 OID 36865)
-- Name: sa30_quo_det sa30_quo_det_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_det
    ADD CONSTRAINT sa30_quo_det_wb_id_fkey FOREIGN KEY (wb_id) REFERENCES public.wb01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5637 (class 2606 OID 36860)
-- Name: sa30_quo_det sa30_quo_det_wh_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_det
    ADD CONSTRAINT sa30_quo_det_wh_id_fkey FOREIGN KEY (wh_id) REFERENCES public.wh01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5629 (class 2606 OID 36818)
-- Name: sa30_quo_hdr sa30_quo_hdr_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_hdr
    ADD CONSTRAINT sa30_quo_hdr_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5630 (class 2606 OID 36813)
-- Name: sa30_quo_hdr sa30_quo_hdr_cust_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_hdr
    ADD CONSTRAINT sa30_quo_hdr_cust_id_fkey FOREIGN KEY (cust_id) REFERENCES public.dl01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5631 (class 2606 OID 36823)
-- Name: sa30_quo_hdr sa30_quo_hdr_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_hdr
    ADD CONSTRAINT sa30_quo_hdr_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5638 (class 2606 OID 36895)
-- Name: sa30_quo_hist sa30_quo_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_hist
    ADD CONSTRAINT sa30_quo_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5639 (class 2606 OID 36890)
-- Name: sa30_quo_hist sa30_quo_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa30_quo_hist
    ADD CONSTRAINT sa30_quo_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.sa30_quo_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5643 (class 2606 OID 36975)
-- Name: sa31_ord_det sa31_ord_det_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_det
    ADD CONSTRAINT sa31_ord_det_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5644 (class 2606 OID 36955)
-- Name: sa31_ord_det sa31_ord_det_hdr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_det
    ADD CONSTRAINT sa31_ord_det_hdr_id_fkey FOREIGN KEY (hdr_id) REFERENCES public.sa31_ord_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5645 (class 2606 OID 36960)
-- Name: sa31_ord_det sa31_ord_det_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_det
    ADD CONSTRAINT sa31_ord_det_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5646 (class 2606 OID 36980)
-- Name: sa31_ord_det sa31_ord_det_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_det
    ADD CONSTRAINT sa31_ord_det_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5647 (class 2606 OID 36970)
-- Name: sa31_ord_det sa31_ord_det_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_det
    ADD CONSTRAINT sa31_ord_det_wb_id_fkey FOREIGN KEY (wb_id) REFERENCES public.wb01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5648 (class 2606 OID 36965)
-- Name: sa31_ord_det sa31_ord_det_wh_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_det
    ADD CONSTRAINT sa31_ord_det_wh_id_fkey FOREIGN KEY (wh_id) REFERENCES public.wh01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5640 (class 2606 OID 36923)
-- Name: sa31_ord_hdr sa31_ord_hdr_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_hdr
    ADD CONSTRAINT sa31_ord_hdr_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5641 (class 2606 OID 36918)
-- Name: sa31_ord_hdr sa31_ord_hdr_cust_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_hdr
    ADD CONSTRAINT sa31_ord_hdr_cust_id_fkey FOREIGN KEY (cust_id) REFERENCES public.dl01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5642 (class 2606 OID 36928)
-- Name: sa31_ord_hdr sa31_ord_hdr_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_hdr
    ADD CONSTRAINT sa31_ord_hdr_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5649 (class 2606 OID 37000)
-- Name: sa31_ord_hist sa31_ord_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_hist
    ADD CONSTRAINT sa31_ord_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5650 (class 2606 OID 36995)
-- Name: sa31_ord_hist sa31_ord_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa31_ord_hist
    ADD CONSTRAINT sa31_ord_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.sa31_ord_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5654 (class 2606 OID 37080)
-- Name: sa32_inv_det sa32_inv_det_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_det
    ADD CONSTRAINT sa32_inv_det_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5655 (class 2606 OID 37060)
-- Name: sa32_inv_det sa32_inv_det_hdr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_det
    ADD CONSTRAINT sa32_inv_det_hdr_id_fkey FOREIGN KEY (hdr_id) REFERENCES public.sa32_inv_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5656 (class 2606 OID 37065)
-- Name: sa32_inv_det sa32_inv_det_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_det
    ADD CONSTRAINT sa32_inv_det_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5657 (class 2606 OID 37085)
-- Name: sa32_inv_det sa32_inv_det_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_det
    ADD CONSTRAINT sa32_inv_det_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5658 (class 2606 OID 37075)
-- Name: sa32_inv_det sa32_inv_det_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_det
    ADD CONSTRAINT sa32_inv_det_wb_id_fkey FOREIGN KEY (wb_id) REFERENCES public.wb01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5659 (class 2606 OID 37070)
-- Name: sa32_inv_det sa32_inv_det_wh_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_det
    ADD CONSTRAINT sa32_inv_det_wh_id_fkey FOREIGN KEY (wh_id) REFERENCES public.wh01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5651 (class 2606 OID 37028)
-- Name: sa32_inv_hdr sa32_inv_hdr_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_hdr
    ADD CONSTRAINT sa32_inv_hdr_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5652 (class 2606 OID 37023)
-- Name: sa32_inv_hdr sa32_inv_hdr_cust_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_hdr
    ADD CONSTRAINT sa32_inv_hdr_cust_id_fkey FOREIGN KEY (cust_id) REFERENCES public.dl01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5653 (class 2606 OID 37033)
-- Name: sa32_inv_hdr sa32_inv_hdr_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_hdr
    ADD CONSTRAINT sa32_inv_hdr_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5660 (class 2606 OID 37105)
-- Name: sa32_inv_hist sa32_inv_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_hist
    ADD CONSTRAINT sa32_inv_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5661 (class 2606 OID 37100)
-- Name: sa32_inv_hist sa32_inv_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa32_inv_hist
    ADD CONSTRAINT sa32_inv_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.sa32_inv_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5665 (class 2606 OID 37185)
-- Name: sa33_crn_det sa33_crn_det_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_det
    ADD CONSTRAINT sa33_crn_det_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5666 (class 2606 OID 37165)
-- Name: sa33_crn_det sa33_crn_det_hdr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_det
    ADD CONSTRAINT sa33_crn_det_hdr_id_fkey FOREIGN KEY (hdr_id) REFERENCES public.sa33_crn_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5667 (class 2606 OID 37170)
-- Name: sa33_crn_det sa33_crn_det_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_det
    ADD CONSTRAINT sa33_crn_det_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5668 (class 2606 OID 37190)
-- Name: sa33_crn_det sa33_crn_det_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_det
    ADD CONSTRAINT sa33_crn_det_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5669 (class 2606 OID 37180)
-- Name: sa33_crn_det sa33_crn_det_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_det
    ADD CONSTRAINT sa33_crn_det_wb_id_fkey FOREIGN KEY (wb_id) REFERENCES public.wb01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5670 (class 2606 OID 37175)
-- Name: sa33_crn_det sa33_crn_det_wh_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_det
    ADD CONSTRAINT sa33_crn_det_wh_id_fkey FOREIGN KEY (wh_id) REFERENCES public.wh01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5662 (class 2606 OID 37133)
-- Name: sa33_crn_hdr sa33_crn_hdr_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_hdr
    ADD CONSTRAINT sa33_crn_hdr_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5663 (class 2606 OID 37128)
-- Name: sa33_crn_hdr sa33_crn_hdr_cust_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_hdr
    ADD CONSTRAINT sa33_crn_hdr_cust_id_fkey FOREIGN KEY (cust_id) REFERENCES public.dl01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5664 (class 2606 OID 37138)
-- Name: sa33_crn_hdr sa33_crn_hdr_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_hdr
    ADD CONSTRAINT sa33_crn_hdr_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5671 (class 2606 OID 37210)
-- Name: sa33_crn_hist sa33_crn_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_hist
    ADD CONSTRAINT sa33_crn_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5672 (class 2606 OID 37205)
-- Name: sa33_crn_hist sa33_crn_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sa33_crn_hist
    ADD CONSTRAINT sa33_crn_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.sa33_crn_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5575 (class 2606 OID 36207)
-- Name: st01_mast st01_mast_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st01_mast
    ADD CONSTRAINT st01_mast_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.st02_cat(id) ON DELETE SET NULL;


--
-- TOC entry 5576 (class 2606 OID 36212)
-- Name: st01_mast st01_mast_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st01_mast
    ADD CONSTRAINT st01_mast_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5574 (class 2606 OID 36183)
-- Name: st02_cat st02_cat_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st02_cat
    ADD CONSTRAINT st02_cat_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5694 (class 2606 OID 37932)
-- Name: st04_stock_uom st04_stock_uom_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st04_stock_uom
    ADD CONSTRAINT st04_stock_uom_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id);


--
-- TOC entry 5695 (class 2606 OID 37937)
-- Name: st04_stock_uom st04_stock_uom_uom_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st04_stock_uom
    ADD CONSTRAINT st04_stock_uom_uom_id_fkey FOREIGN KEY (uom_id) REFERENCES public.st03_uom_master(id);


--
-- TOC entry 5696 (class 2606 OID 37980)
-- Name: st30_trans st30_trans_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st30_trans
    ADD CONSTRAINT st30_trans_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5577 (class 2606 OID 36271)
-- Name: st40_hist st40_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st40_hist
    ADD CONSTRAINT st40_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5578 (class 2606 OID 36266)
-- Name: st40_hist st40_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.st40_hist
    ADD CONSTRAINT st40_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.st01_mast(id) ON DELETE CASCADE;


--
-- TOC entry 5558 (class 2606 OID 35929)
-- Name: sy00_user sy00_user_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy00_user
    ADD CONSTRAINT sy00_user_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.sy04_role(id) ON DELETE RESTRICT;


--
-- TOC entry 5559 (class 2606 OID 35942)
-- Name: sy01_sess sy01_sess_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy01_sess
    ADD CONSTRAINT sy01_sess_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.sy00_user(id) ON DELETE CASCADE;


--
-- TOC entry 5560 (class 2606 OID 35957)
-- Name: sy02_logs sy02_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy02_logs
    ADD CONSTRAINT sy02_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5556 (class 2606 OID 35911)
-- Name: sy06_role_perm sy06_role_perm_perm_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy06_role_perm
    ADD CONSTRAINT sy06_role_perm_perm_id_fkey FOREIGN KEY (perm_id) REFERENCES public.sy05_perm(id) ON DELETE CASCADE;


--
-- TOC entry 5557 (class 2606 OID 35906)
-- Name: sy06_role_perm sy06_role_perm_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy06_role_perm
    ADD CONSTRAINT sy06_role_perm_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.sy04_role(id) ON DELETE CASCADE;


--
-- TOC entry 5561 (class 2606 OID 35987)
-- Name: sy07_doc_num sy07_doc_num_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy07_doc_num
    ADD CONSTRAINT sy07_doc_num_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5562 (class 2606 OID 36015)
-- Name: sy40_hist sy40_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sy40_hist
    ADD CONSTRAINT sy40_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5572 (class 2606 OID 36167)
-- Name: wb01_mast wb01_mast_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb01_mast
    ADD CONSTRAINT wb01_mast_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5573 (class 2606 OID 36162)
-- Name: wb01_mast wb01_mast_wh_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb01_mast
    ADD CONSTRAINT wb01_mast_wh_id_fkey FOREIGN KEY (wh_id) REFERENCES public.wh01_mast(id) ON DELETE CASCADE;


--
-- TOC entry 5579 (class 2606 OID 36297)
-- Name: wb30_trf_hdr wb30_trf_hdr_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb30_trf_hdr
    ADD CONSTRAINT wb30_trf_hdr_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5580 (class 2606 OID 36287)
-- Name: wb30_trf_hdr wb30_trf_hdr_wb_from_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb30_trf_hdr
    ADD CONSTRAINT wb30_trf_hdr_wb_from_fkey FOREIGN KEY (wb_from) REFERENCES public.wb01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5581 (class 2606 OID 36292)
-- Name: wb30_trf_hdr wb30_trf_hdr_wb_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb30_trf_hdr
    ADD CONSTRAINT wb30_trf_hdr_wb_to_fkey FOREIGN KEY (wb_to) REFERENCES public.wb01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5582 (class 2606 OID 36312)
-- Name: wb31_trf_det wb31_trf_det_hdr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb31_trf_det
    ADD CONSTRAINT wb31_trf_det_hdr_id_fkey FOREIGN KEY (hdr_id) REFERENCES public.wb30_trf_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5583 (class 2606 OID 36317)
-- Name: wb31_trf_det wb31_trf_det_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb31_trf_det
    ADD CONSTRAINT wb31_trf_det_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5584 (class 2606 OID 36337)
-- Name: wb40_hist wb40_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb40_hist
    ADD CONSTRAINT wb40_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5585 (class 2606 OID 36332)
-- Name: wb40_hist wb40_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wb40_hist
    ADD CONSTRAINT wb40_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.wb30_trf_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5571 (class 2606 OID 36146)
-- Name: wh01_mast wh01_mast_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh01_mast
    ADD CONSTRAINT wh01_mast_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5673 (class 2606 OID 37265)
-- Name: wh30_trans wh30_trans_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trans
    ADD CONSTRAINT wh30_trans_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5674 (class 2606 OID 37260)
-- Name: wh30_trans wh30_trans_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trans
    ADD CONSTRAINT wh30_trans_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5675 (class 2606 OID 37270)
-- Name: wh30_trans wh30_trans_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trans
    ADD CONSTRAINT wh30_trans_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5676 (class 2606 OID 37255)
-- Name: wh30_trans wh30_trans_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trans
    ADD CONSTRAINT wh30_trans_wb_id_fkey FOREIGN KEY (wb_id) REFERENCES public.wb01_mast(id) ON DELETE SET NULL;


--
-- TOC entry 5677 (class 2606 OID 37250)
-- Name: wh30_trans wh30_trans_wh_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trans
    ADD CONSTRAINT wh30_trans_wh_id_fkey FOREIGN KEY (wh_id) REFERENCES public.wh01_mast(id) ON DELETE SET NULL;


--
-- TOC entry 5680 (class 2606 OID 37335)
-- Name: wh30_trf_hdr wh30_trf_hdr_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trf_hdr
    ADD CONSTRAINT wh30_trf_hdr_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5681 (class 2606 OID 37325)
-- Name: wh30_trf_hdr wh30_trf_hdr_from_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trf_hdr
    ADD CONSTRAINT wh30_trf_hdr_from_wb_id_fkey FOREIGN KEY (from_wb_id) REFERENCES public.wb01_mast(id) ON DELETE SET NULL;


--
-- TOC entry 5682 (class 2606 OID 37315)
-- Name: wh30_trf_hdr wh30_trf_hdr_from_wh_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trf_hdr
    ADD CONSTRAINT wh30_trf_hdr_from_wh_id_fkey FOREIGN KEY (from_wh_id) REFERENCES public.wh01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5683 (class 2606 OID 37330)
-- Name: wh30_trf_hdr wh30_trf_hdr_to_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trf_hdr
    ADD CONSTRAINT wh30_trf_hdr_to_wb_id_fkey FOREIGN KEY (to_wb_id) REFERENCES public.wb01_mast(id) ON DELETE SET NULL;


--
-- TOC entry 5684 (class 2606 OID 37320)
-- Name: wh30_trf_hdr wh30_trf_hdr_to_wh_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trf_hdr
    ADD CONSTRAINT wh30_trf_hdr_to_wh_id_fkey FOREIGN KEY (to_wh_id) REFERENCES public.wh01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5685 (class 2606 OID 37340)
-- Name: wh30_trf_hdr wh30_trf_hdr_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh30_trf_hdr
    ADD CONSTRAINT wh30_trf_hdr_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5686 (class 2606 OID 37385)
-- Name: wh31_trf_det wh31_trf_det_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh31_trf_det
    ADD CONSTRAINT wh31_trf_det_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5687 (class 2606 OID 37375)
-- Name: wh31_trf_det wh31_trf_det_from_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh31_trf_det
    ADD CONSTRAINT wh31_trf_det_from_wb_id_fkey FOREIGN KEY (from_wb_id) REFERENCES public.wb01_mast(id) ON DELETE SET NULL;


--
-- TOC entry 5688 (class 2606 OID 37365)
-- Name: wh31_trf_det wh31_trf_det_hdr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh31_trf_det
    ADD CONSTRAINT wh31_trf_det_hdr_id_fkey FOREIGN KEY (hdr_id) REFERENCES public.wh30_trf_hdr(id) ON DELETE CASCADE;


--
-- TOC entry 5689 (class 2606 OID 37370)
-- Name: wh31_trf_det wh31_trf_det_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh31_trf_det
    ADD CONSTRAINT wh31_trf_det_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.st01_mast(id) ON DELETE RESTRICT;


--
-- TOC entry 5690 (class 2606 OID 37380)
-- Name: wh31_trf_det wh31_trf_det_to_wb_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh31_trf_det
    ADD CONSTRAINT wh31_trf_det_to_wb_id_fkey FOREIGN KEY (to_wb_id) REFERENCES public.wb01_mast(id) ON DELETE SET NULL;


--
-- TOC entry 5691 (class 2606 OID 37390)
-- Name: wh31_trf_det wh31_trf_det_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh31_trf_det
    ADD CONSTRAINT wh31_trf_det_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5678 (class 2606 OID 37295)
-- Name: wh40_hist wh40_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh40_hist
    ADD CONSTRAINT wh40_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5679 (class 2606 OID 37290)
-- Name: wh40_hist wh40_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh40_hist
    ADD CONSTRAINT wh40_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.wh30_trans(id) ON DELETE CASCADE;


--
-- TOC entry 5692 (class 2606 OID 37412)
-- Name: wh40_trf_hist wh40_trf_hist_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh40_trf_hist
    ADD CONSTRAINT wh40_trf_hist_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.sy00_user(id) ON DELETE SET NULL;


--
-- TOC entry 5693 (class 2606 OID 37407)
-- Name: wh40_trf_hist wh40_trf_hist_ref_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wh40_trf_hist
    ADD CONSTRAINT wh40_trf_hist_ref_id_fkey FOREIGN KEY (ref_id) REFERENCES public.wh30_trf_hdr(id) ON DELETE CASCADE;


-- Completed on 2025-11-22 09:17:54

--
-- PostgreSQL database dump complete
--

-- Completed on 2025-11-22 09:17:54

--
-- PostgreSQL database cluster dump complete
--

