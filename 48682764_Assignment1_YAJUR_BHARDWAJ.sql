-- ============================================================
-- BUSA8090 Assignment 1 – David Jones Marketing Analytics
-- Case Study: David Jones EOFY 2025 Sale
-- AUTHOR: Yajur Bhardwaj | Student ID:48682764
-- Unit: BUSA8090 Data and Visualisation for Business

--
-- This database is designed not only for transaction processing,
-- but also for marketing attribution, customer journey analysis,
-- and campaign performance optimisation.
--
-- I designed this database to support comprehensive analysis
-- of customer behaviour, social media CTR, and campaign ROI
-- for David Jones's End of Financial Year sale campaign.
-- The schema tracks the full customer journey from seeing
-- a social media ad, clicking through to the website, browsing
-- products, and completing a purchase.
-- ============================================================



CREATE DATABASE DavidJonesMarketing;
USE DavidJonesMarketing;

-- ============================================================
-- PART A-B: DATABASE SCHEMA (CREATE TABLES)
--
-- I chose 11 core entities plus CampaignTouchpoint as an analytical journey table that together capture the complete
-- marketing funnel: platform → campaign → ad → interaction
-- → session → order → product → review.
-- ============================================================

-- ============================================================
-- Table 1: Customer
-- I store customer demographics and loyalty tier here.
-- MembershipTier drives my loyalty segmentation queries.
-- The CHECK constraint ensures only valid tier values
-- can be inserted, protecting data integrity.
-- ============================================================



CREATE TABLE Customer (
    CustomerID       INT          PRIMARY KEY AUTO_INCREMENT,  -- unique ID auto-generated for each customer
    FirstName        VARCHAR(50)  NOT NULL,                    -- customer first name, required field
    LastName         VARCHAR(50)  NOT NULL,                    -- customer last name, required field 
    Email            VARCHAR(100) UNIQUE NOT NULL,             -- I enforce uniqueness so no duplicate accounts exist
    DateOfBirth      DATE,                                     -- used for age-based demographic segmentation
    Gender           VARCHAR(10),                              -- supports gender targeting in campaigns
    State            VARCHAR(50),                              -- Australian state for geographic revenue analysis
    City             VARCHAR(60),                              -- city-level detail for geo-targeted ads
    MembershipTier   VARCHAR(20)  DEFAULT 'Bronze'             -- defaults to Bronze if not specified
                     CHECK (MembershipTier IN ('Bronze','Silver','Gold','Platinum')), -- only valid tiers allowed
    RegistrationDate DATE         NOT NULL                     -- tracks when the customer joined David Jones
);

-- ============================================================
-- Table 2: Category
-- I created a separate Category entity so product categories
-- are managed centrally. This avoids data redundancy and allows
-- the business to rename categories without updating every product .
-- ============================================================



CREATE TABLE Category (
    CategoryID   INT          PRIMARY KEY AUTO_INCREMENT, -- unique ID for each category
    CategoryName VARCHAR(80)  NOT NULL UNIQUE,            -- category name must be unique
    Description  VARCHAR(200)                             -- brief description of the category
);

-- ============================================================
-- Table 3: Product
-- I store both original and sale price so I can calculate
-- the discount applied during the EOFY campaign.
-- CategoryID links each product to its parent category
-- rather than storing category as plain text, which avoids
-- data redundancy and supports category-level analysis.
-- ============================================================

CREATE TABLE Product (
    ProductID       INT           PRIMARY KEY AUTO_INCREMENT, -- unique ID auto-generated for each product
    ProductName     VARCHAR(150)  NOT NULL,                   -- full product name as listed on davidjones.com
    CategoryID      INT           NOT NULL,                   -- links product to its parent category
    SubCategory     VARCHAR(60),                              -- more specific classification within category
    Brand           VARCHAR(80),                              -- brand name e.g. Sheridan, Sony, Oroton
    OriginalPrice   DECIMAL(10,2) NOT NULL,                   -- full retail price before EOFY discount
    SalePrice       DECIMAL(10,2) NOT NULL,                   -- discounted EOFY sale price
    StockQuantity   INT           DEFAULT 0,                  -- current stock level, defaults to 0
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID) -- each product must belong to a valid category
);

-- ============================================================
-- Table 4: SocialMediaPlatform
-- I include MonthlyActiveUsers so my queries can put CTR
-- results in context. A 2% CTR means something different
-- on a platform with 5M users vs 17M users.
-- ============================================================

CREATE TABLE SocialMediaPlatform (
    PlatformID         INT          PRIMARY KEY AUTO_INCREMENT, -- unique ID for each platform
    PlatformName       VARCHAR(50)  NOT NULL,                   -- e.g. Instagram, Facebook, TikTok
    MonthlyActiveUsers BIGINT,                                  -- Australian monthly active user count
    AuDemographic      VARCHAR(150)                             -- Australian audience profile for targeting context
);


-- ============================================================
-- Table 5: MarketingCampaign
-- I track budget, dates, and target audience so I can
-- calculate ROI and assess whether we reached the right
-- demographic with each campaign.
-- ============================================================

CREATE TABLE MarketingCampaign (
    CampaignID        INT           PRIMARY KEY AUTO_INCREMENT, -- unique ID for each campaign
    CampaignName      VARCHAR(120)  NOT NULL,                   -- descriptive name of the campaign
    StartDate         DATE          NOT NULL,                   -- campaign launch date
    EndDate           DATE          NOT NULL,                   -- campaign end date
    TotalBudget       DECIMAL(12,2) NOT NULL,                   -- total money allocated to this campaign
    CampaignObjective VARCHAR(60),                              -- e.g. Conversion, Awareness, Engagement
    TargetAgeMin      INT,                                      -- minimum age of target audience
    TargetAgeMax      INT,                                      -- maximum age of target audience
    TargetGender      VARCHAR(10)   DEFAULT 'All'               -- target gender, defaults to all
);

-- ============================================================
-- Table 6: Advertisement
-- I link each ad to both a campaign and a platform.
-- TotalImpressions lets me calculate CTR in my queries.
-- AdType records the creative format used (Reel, Story etc)
-- which supports my ad format performance analysis in Q7.
-- ============================================================


CREATE TABLE Advertisement (
    AdID             INT           PRIMARY KEY AUTO_INCREMENT, -- unique ID for each advertisement
    CampaignID       INT           NOT NULL,                   -- links ad to its parent campaign
    PlatformID       INT           NOT NULL,                   -- links ad to the platform it runs on
    AdType           VARCHAR(50),                              -- e.g. Reel, Story, Post, Carousel, Tweet
    AdContent        TEXT,                                     -- the actual ad copy or description
    PublishDate      DATE,                                     -- date the ad went live
    BudgetAllocated  DECIMAL(10,2),                            -- money allocated to this specific ad
    TotalImpressions INT           DEFAULT 0,                  -- total times ad was shown to users
    FOREIGN KEY (CampaignID) REFERENCES MarketingCampaign(CampaignID), -- must belong to a valid campaign
    FOREIGN KEY (PlatformID) REFERENCES SocialMediaPlatform(PlatformID) -- must run on a valid platform
);

-- ============================================================
-- Table 7: WebsiteSession
-- I capture each customer visit including device type and
-- referral source. This is critical for understanding which
-- channels drive traffic and whether users bounce or engage.
-- BounceFlag and PagesViewed support my abandonment analysis
-- in Q10.
-- ============================================================

CREATE TABLE WebsiteSession (
    SessionID       INT          PRIMARY KEY AUTO_INCREMENT, -- unique ID for each website visit
    CustomerID      INT,                                     -- links session to a customer
    SessionDate     DATETIME     NOT NULL,                   -- exact date and time of the visit
    SessionDuration INT,                                     -- length of visit in seconds
    PagesViewed     INT,                                     -- number of pages viewed in this session
    DeviceType      VARCHAR(20),                             -- Mobile, Desktop, or Tablet
    ReferralSource  VARCHAR(60),                             -- where the customer came from e.g. Social-Instagram
    BounceFlag      TINYINT(1)   DEFAULT 0,                  -- 1 = bounced immediately, 0 = engaged
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) -- session must belong to a valid customer
);

-- ============================================================
-- Table 8: CustomerOrder
-- I added IsEOFYSale as a flag so I can instantly filter
-- for sale-period orders without needing date calculations
-- in every query. This speeds up all my analytical queries
-- significantly.
-- ============================================================

CREATE TABLE CustomerOrder (
    OrderID         INT            PRIMARY KEY AUTO_INCREMENT, -- unique ID for each order
    CustomerID      INT            NOT NULL,                   -- links order to the customer who placed it
    SessionID       INT,                                       -- links order to the website session it came from
    OrderDate       DATETIME       NOT NULL,                   -- exact date and time order was placed
    TotalAmount     DECIMAL(10,2)  NOT NULL,                   -- total value of the order
    DiscountApplied DECIMAL(10,2)  DEFAULT 0.00,               -- discount amount applied at checkout
    PaymentMethod   VARCHAR(50),                               -- e.g. Credit Card, PayPal, AMEX
    OrderStatus     VARCHAR(30)    DEFAULT 'Completed',        -- e.g. Completed, Cancelled, Pending
    IsEOFYSale      TINYINT(1)     DEFAULT 0,                  -- 1 = placed during EOFY campaign window
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),  -- must belong to a valid customer
    FOREIGN KEY (SessionID)  REFERENCES WebsiteSession(SessionID) -- must link to a valid session
);

-- ============================================================
-- Table 9: OrderItem
-- I separate line items from the order header so I can
-- analyse revenue at the product and category level.
-- Without this table I could not run category-level queries.
-- Each row represents one product line within an order.
-- ============================================================

CREATE TABLE OrderItem (
    OrderItemID     INT           PRIMARY KEY AUTO_INCREMENT, -- unique ID for each order line item
    OrderID         INT           NOT NULL,                   -- links item to its parent order
    ProductID       INT           NOT NULL,                   -- links item to the product purchased
    Quantity        INT           DEFAULT 1,                  -- number of units purchased
    UnitPrice       DECIMAL(10,2) NOT NULL,                   -- price per unit at time of purchase
    DiscountPercent DECIMAL(5,2)  DEFAULT 0.00,               -- percentage discount applied to this item
    FOREIGN KEY (OrderID)   REFERENCES CustomerOrder(OrderID), -- must belong to a valid order
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)      -- must link to a valid product
);

-- ============================================================
-- Table 10: AdInteraction
-- This is the most important table for my CTR analysis.
-- I store every impression, click, like and share so I
-- can calculate platform-level and ad-level CTR precisely.
-- ConvertedToOrder and OrderID link ad clicks directly
-- to purchases, enabling full attribution analysis.
-- ============================================================

CREATE TABLE AdInteraction (
    InteractionID   INT           PRIMARY KEY AUTO_INCREMENT, -- unique ID for each interaction event
    AdID            INT           NOT NULL,                   -- links interaction to the specific ad
    CustomerID      INT           NOT NULL,                   -- links interaction to the customer who interacted
    InteractionDate DATETIME      NOT NULL,                   -- exact date and time of the interaction
    InteractionType VARCHAR(30),                              -- Impression, Click, Like or Share
    ConvertedToOrder TINYINT(1)   DEFAULT 0,                  -- 1 = this interaction led to a purchase
    OrderID         INT,                                      -- links to the order if converted
    FOREIGN KEY (AdID)       REFERENCES Advertisement(AdID),       -- must link to a valid ad
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),      -- must link to a valid customer
    FOREIGN KEY (OrderID)    REFERENCES CustomerOrder(OrderID)     -- links to order only if converted
);


-- ============================================================
-- Table 11: ProductReview
-- I include reviews so I can analyse post-purchase sentiment
-- by product category and correlate ratings with sales volume
-- during the EOFY campaign. The CHECK constraint ensures
-- ratings are always between 1 and 5.
-- ============================================================

CREATE TABLE ProductReview (
    ReviewID    INT           PRIMARY KEY AUTO_INCREMENT, -- unique ID for each review
    ProductID   INT           NOT NULL,                   -- links review to the product being reviewed
    CustomerID  INT           NOT NULL,                   -- links review to the customer who wrote it
    Rating      INT           CHECK (Rating BETWEEN 1 AND 5), -- star rating must be between 1 and 5
    ReviewText  TEXT,                                     -- the written review content
    ReviewDate  DATE          NOT NULL,                   -- date the review was submitted
    FOREIGN KEY (ProductID)  REFERENCES Product(ProductID),   -- must link to a valid product
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)  -- must link to a valid customer
);

-- ============================================================
-- Table 12: CampaignTouchpoint
-- I added this unique table to track the full multi-step
-- customer journey from first ad exposure through to purchase.
-- Most databases only capture the final transaction. By
-- recording every touchpoint stage I can identify exactly
-- where customers drop out of the funnel and which campaigns
-- guide the most customers to conversion.
-- This positions my database as a marketing attribution
-- system, not just an order management system.
-- ============================================================

CREATE TABLE CampaignTouchpoint (
    TouchpointID    INT          PRIMARY KEY AUTO_INCREMENT, -- unique ID for each touchpoint event
    CustomerID      INT          NOT NULL,                   -- links touchpoint to the customer
    CampaignID      INT          NOT NULL,                   -- links touchpoint to the campaign
    TouchpointDate  DATETIME     NOT NULL,                   -- exact date and time of the touchpoint
    TouchpointStage VARCHAR(30)  CHECK (TouchpointStage IN  -- stage must be one of these valid values
                    ('Awareness','Consideration','Cart','Purchase','Retargeting')),
    Channel         VARCHAR(50),                             -- e.g. Instagram, Website, Email
    Notes           VARCHAR(255),                            -- description of what happened at this touchpoint
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),       -- must link to a valid customer
    FOREIGN KEY (CampaignID) REFERENCES MarketingCampaign(CampaignID) -- must link to a valid campaign
);

-- ============================================================
-- ADDITIONAL CONSTRAINTS
-- I added these after the initial schema to enforce business
-- rules at the database level. This prevents bad data from
-- entering the system.
-- ============================================================

-- Sale price must make commercial sense
ALTER TABLE Product
ADD CONSTRAINT chk_product_prices
CHECK (OriginalPrice > 0 AND SalePrice > 0 AND SalePrice <= OriginalPrice);

-- Stock can never go negative
ALTER TABLE Product
ADD CONSTRAINT chk_stock_quantity
CHECK (StockQuantity >= 0);

-- A campaign cannot end before it starts
ALTER TABLE MarketingCampaign
ADD CONSTRAINT chk_campaign_dates
CHECK (EndDate >= StartDate);

-- Ad budget and impressions cannot be negative
ALTER TABLE Advertisement
ADD CONSTRAINT chk_ad_budget
CHECK (BudgetAllocated >= 0 AND TotalImpressions >= 0);

-- Session values must be non-negative
ALTER TABLE WebsiteSession
ADD CONSTRAINT chk_session_values
CHECK (SessionDuration >= 0 AND PagesViewed >= 0);

-- Order amounts must be valid
ALTER TABLE CustomerOrder
ADD CONSTRAINT chk_order_amount
CHECK (TotalAmount >= 0 AND DiscountApplied >= 0);

-- Quantity must be at least 1 and discount a valid percentage
ALTER TABLE OrderItem
ADD CONSTRAINT chk_order_item_values
CHECK (Quantity > 0 AND UnitPrice > 0 AND DiscountPercent BETWEEN 0 AND 100);

-- I restrict DeviceType to standard web analytics categories.
-- Laptops are classified under Desktop as industry tools like
-- Google Analytics and Meta Ads cannot distinguish between
-- a laptop and a desktop browser session.
ALTER TABLE WebsiteSession
ADD CONSTRAINT chk_device_type
CHECK (DeviceType IN ('Mobile', 'Desktop', 'Tablet'));

-- ============================================================
-- INDEXES
-- I created these indexes on the columns I join and filter
-- most frequently in my analytical queries. This ensures
-- the database performs efficiently even as data scales up.
-- ============================================================

-- I index email as it is the most common customer lookup field
CREATE INDEX idx_customer_email     ON Customer(Email);

-- I index OrderDate as most revenue queries filter by date
CREATE INDEX idx_order_date         ON CustomerOrder(OrderDate);

-- I index CustomerID on sessions for fast customer journey lookups
CREATE INDEX idx_session_customer   ON WebsiteSession(CustomerID);

-- I index AdID on interactions for fast CTR calculations
CREATE INDEX idx_adinteraction_ad   ON AdInteraction(AdID);

-- I index CustomerID on interactions for customer attribution queries
CREATE INDEX idx_adinteraction_cust ON AdInteraction(CustomerID);

-- I index ProductID on order items for fast category revenue queries
CREATE INDEX idx_orderitem_product  ON OrderItem(ProductID);

-- I index PlatformID on ads for fast platform performance queries
CREATE INDEX idx_ad_platform        ON Advertisement(PlatformID);

-- I index CampaignID on ads for fast campaign ROI queries
CREATE INDEX idx_ad_campaign        ON Advertisement(CampaignID);

-- I index SessionID on orders to link sessions to purchases quickly
CREATE INDEX idx_order_session      ON CustomerOrder(SessionID);


-- ============================================================
-- TRIGGER: trg_stock_update
-- I added this trigger to automatically reduce product stock
-- levels whenever a new OrderItem is inserted. This reflects
-- real-world inventory management — when a customer buys an
-- item the warehouse stock count decreases automatically
-- without requiring a separate UPDATE statement.
-- This enforces business logic at the database layer, not
-- just the application layer.
-- ============================================================

CREATE TRIGGER trg_stock_update
AFTER INSERT ON OrderItem
FOR EACH ROW
UPDATE Product
SET StockQuantity = StockQuantity - NEW.Quantity
WHERE ProductID = NEW.ProductID;

-- ============================================================
-- VIEW: CustomerJourneySummary
-- I created this view to give marketing analysts a quick
-- summary of how each customer moved through the funnel
-- for each campaign. A view abstracts the underlying JOIN
-- complexity so business users can query it simply without
-- needing to write complex SQL every time.
-- ============================================================

CREATE VIEW CustomerJourneySummary AS
SELECT
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName)                              AS CustomerName,
    c.MembershipTier,
    mc.CampaignName,
    COUNT(ct.TouchpointID)                                            AS TotalTouchpoints,
    MAX(CASE WHEN ct.TouchpointStage = 'Purchase' THEN 1 ELSE 0 END) AS Converted
FROM CampaignTouchpoint ct
JOIN Customer         c  ON ct.CustomerID = c.CustomerID
JOIN MarketingCampaign mc ON ct.CampaignID = mc.CampaignID
GROUP BY c.CustomerID, CustomerName, c.MembershipTier, mc.CampaignName;

-- ============================================================
-- PART A-C: DUMMY DATA
-- I populated the database with realistic data covering the
-- EOFY sale period (June 2025). The data reflects genuine
-- Australian retail patterns: NSW and VIC customers dominate,
-- Instagram drives the most interactions, and mobile sessions
-- outnumber desktop sessions roughly 2:1.
-- ============================================================

-- --------------------------------------------------------
-- Categories (10 rows)
-- I created 10 categories that mirror David Jones's actual
-- product department structure on davidjones.com
-- --------------------------------------------------------

INSERT INTO Category (CategoryName, Description) VALUES
('Clothing',        'Apparel including outerwear, knitwear, bottoms and sleepwear'),
('Footwear',        'Shoes, sneakers, boots and sports footwear'),
('Beauty',          'Skincare, makeup, fragrance and personal care products'),
('Electronics',     'Audio, wearables, appliances and smart home devices'),
('Home',            'Bedding, dining, textiles, decor and homewares'),
('Accessories',     'Bags, eyewear, ties and fashion accessories'),
('Sportswear',      'Active wear and sports performance clothing'),
('Jewellery',       'Fine jewellery, watches and luxury accessories'),
('Kids',            'Clothing, toys and accessories for children'),
('Gifting',         'Gift sets, hampers and seasonal gift collections');

-- --------------------------------------------------------
-- Customers (25 rows)
-- I included a mix of states, genders, ages and membership
-- tiers to support segmentation analysis in my queries.
-- NSW and VIC dominate reflecting David Jones store locations.
-- --------------------------------------------------------
INSERT INTO Customer (FirstName, LastName, Email, DateOfBirth, Gender, State, City, MembershipTier, RegistrationDate) VALUES
('Zara',     'Patel',     'zara.patel@outlook.com',      '1994-02-12', 'Female', 'NSW', 'Sydney',          'Platinum', '2017-03-08'),
('Marcus',   'OBrien',    'marcus.obrien@gmail.com',     '1986-09-03', 'Male',   'VIC', 'Melbourne',       'Gold',     '2019-05-20'),
('Priya',    'Sharma',    'priya.sharma@hotmail.com',    '1997-06-28', 'Female', 'QLD', 'Brisbane',        'Silver',   '2021-08-15'),
('Caleb',    'Thornton',  'caleb.thornton@gmail.com',    '1991-11-17', 'Male',   'WA',  'Perth',           'Bronze',   '2023-04-01'),
('Tessa',    'Whitfield', 'tessa.whitfield@outlook.com', '1989-04-05', 'Female', 'NSW', 'Parramatta',      'Gold',     '2020-07-22'),
('Dominic',  'Russo',     'dominic.russo@gmail.com',     '1983-07-30', 'Male',   'VIC', 'Richmond',        'Platinum', '2016-11-14'),
('Aaliyah',  'Nguyen',    'aaliyah.nguyen@email.com',    '1999-03-19', 'Female', 'SA',  'Adelaide',        'Bronze',   '2024-01-07'),
('Fletcher', 'MacLeod',   'fletcher.macleod@gmail.com',  '1988-12-04', 'Male',   'NSW', 'Chatswood',       'Silver',   '2021-03-18'),
('Imogen',   'Walsh',     'imogen.walsh@hotmail.com',    '2001-08-22', 'Female', 'QLD', 'Surfers Paradise','Bronze',   '2024-06-01'),
('Luca',     'DiVita',    'luca.divita@outlook.com',     '1993-05-09', 'Male',   'VIC', 'South Yarra',     'Gold',     '2019-10-05'),
('Sabrina',  'Kowalski',  'sabrina.kowalski@gmail.com',  '1996-01-25', 'Female', 'NSW', 'Sydney',          'Platinum', '2018-04-30'),
('Xavier',   'Fontaine',  'xavier.fontaine@email.com',   '1984-10-11', 'Male',   'WA',  'Fremantle',       'Gold',     '2020-02-17'),
('Naomi',    'Takahashi', 'naomi.takahashi@outlook.com', '2000-07-14', 'Female', 'VIC', 'Carlton',         'Silver',   '2022-09-09'),
('Rhys',     'Gallagher', 'rhys.gallagher@gmail.com',    '1995-03-07', 'Male',   'QLD', 'Cairns',          'Bronze',   '2023-12-11'),
('Celeste',  'Beaumont',  'celeste.beaumont@email.com',  '1990-12-02', 'Female', 'NSW', 'Manly',           'Gold',     '2019-08-03'),
('Ashton',   'Lindqvist', 'ashton.lindqvist@gmail.com',  '1998-05-16', 'Male',   'SA',  'Glenelg',         'Bronze',   '2024-02-28'),
('Freya',    'Johansson', 'freya.johansson@hotmail.com', '1987-08-23', 'Female', 'VIC', 'Hawthorn',        'Platinum', '2017-06-19'),
('Rowan',    'Adeyemi',   'rowan.adeyemi@outlook.com',   '2002-02-06', 'Male',   'NSW', 'Liverpool',       'Bronze',   '2023-07-14'),
('Valentina','Cruz',      'valentina.cruz@gmail.com',    '1992-09-30', 'Female', 'WA',  'Subiaco',         'Silver',   '2022-01-25'),
('Mitchell', 'Stafford',  'mitchell.stafford@email.com', '1990-11-13', 'Male',   'QLD', 'Toowoomba',       'Bronze',   '2022-10-08'),
('Annelise', 'Hartmann',  'annelise.hartmann@gmail.com', '1985-03-31', 'Female', 'NSW', 'Sydney',          'Gold',     '2018-12-04'),
('Jonah',    'Brennan',   'jonah.brennan@outlook.com',   '1993-07-08', 'Male',   'VIC', 'Fitzroy',         'Silver',   '2021-05-30'),
('Kiara',    'Osei',      'kiara.osei@gmail.com',        '2003-04-18', 'Female', 'QLD', 'Gold Coast',      'Bronze',   '2024-04-20'),
('Rafferty', 'Sinclair',  'rafferty.sinclair@email.com', '1989-01-27', 'Male',   'NSW', 'Newtown',         'Gold',     '2019-03-12'),
('Margot',   'Leblanc',   'margot.leblanc@hotmail.com',  '1996-06-04', 'Female', 'VIC', 'St Kilda',        'Silver',   '2021-11-02');

-- --------------------------------------------------------
-- Products (20 rows)
-- I selected products across all categories to ensure my
-- category performance queries return varied, useful results.
-- CategoryID: 1=Clothing 2=Footwear 3=Beauty 4=Electronics
--             5=Home 6=Accessories 7=Sportswear 8=Jewellery
--             9=Kids 10=Gifting
-- --------------------------------------------------------

INSERT INTO Product (ProductName, CategoryID, SubCategory, Brand, OriginalPrice, SalePrice, StockQuantity) VALUES
('Structured Leather Shoulder Bag',   6, 'Bags',       'Oroton',              349.00,  209.00,  72),
('Merino Wool Blazer Charcoal',       1, 'Outerwear',  'Sportscraft',         549.00,  319.00,  48),
('Canvas High-Top Sneakers',          2, 'Sneakers',   'Converse',            130.00,   79.00, 155),
('Relaxed Fit Linen Trousers',        1, 'Bottoms',    'Oxford',              159.00,   95.00, 190),
('Eau de Parfum Intens 75ml',         3, 'Fragrance',  'Yves Saint Laurent',  210.00,  155.00,  40),
('Wireless Earbuds Pro Max',          4, 'Audio',      'Sony',                399.00,  279.00,  60),
('1000-Thread Count Sheet Set King',  5, 'Bedding',    'Sheridan',            449.00,  229.00,  55),
('Bean-to-Cup Coffee Machine',        4, 'Appliances', 'Breville',            799.00,  549.00,  18),
('Silk Pocket Square Floral',         6, 'Ties',       'T.M.Lewin',            79.00,   45.00, 175),
('Compression Training Tights',       7, 'Bottoms',    'Lululemon',           149.00,   99.00, 140),
('Vitamin C Brightening Serum 30ml',  3, 'Skincare',   'Kiehls',               95.00,   65.00,  88),
('Oversized Cat-Eye Sunglasses',      6, 'Eyewear',    'Le Specs',             79.00,   45.00, 130),
('Brushed Cotton Crew Neck Sweater',  1, 'Knitwear',   'Country Road',        169.00,   99.00, 105),
('Porcelain Dinnerware Set 20pc',     5, 'Dining',     'Vera Wang',           299.00,  149.00,  42),
('Smart Fitness Tracker Watch',       4, 'Wearables',  'Garmin',              499.00,  349.00,  35),
('Satin-Trim Pyjama Set Navy',        1, 'Sleepwear',  'Calvin Klein',        189.00,  109.00,  68),
('Hand-Woven Merino Throw Rug',       5, 'Textiles',   'Bambury',             179.00,   99.00,  82),
('Mineral Foundation Serum SPF25',    3, 'Makeup',     'Charlotte Tilbury',    89.00,   59.00,  95),
('Trail Running Shoe Carbon',         2, 'Sports',     'Asics',               249.00,  169.00,  90),
('Soy Wax Candle Jasmine Oud 350g',   5, 'Decor',      'In Essence',           69.00,   42.00, 220);

-- --------------------------------------------------------
-- Social Media Platforms (10 rows)
-- I included 10 social and digital platforms to support
-- broader campaign analysis across all major channels
-- David Jones uses for its EOFY marketing.
-- --------------------------------------------------------
INSERT INTO SocialMediaPlatform (PlatformName, MonthlyActiveUsers, AuDemographic) VALUES
('Instagram',  10000000, 'Ages 18-34, female-skewed, high fashion/beauty engagement'),
('Facebook',   17000000, 'Ages 25-54, broad demographic, higher household income'),
('X',           5500000, 'Ages 18-44, male-skewed, tech-savvy, deal-seeking'),
('TikTok',      8200000, 'Ages 16-30, Gen Z skewed, high video engagement, trend-driven'),
('Pinterest',   4100000, 'Ages 25-45, female-skewed, high purchase intent for home and fashion'),
('YouTube',    16000000, 'Ages 18-54, broad demographic, high engagement with product reviews'),
('LinkedIn',    5800000, 'Ages 25-50, professional demographic, higher disposable income'),
('Snapchat',    3900000, 'Ages 13-29, younger skewed, high story and filter engagement'),
('Reddit',      3200000, 'Ages 18-40, male-skewed, highly research-oriented before purchase'),
('Google Ads', 22000000, 'All ages, intent-based search targeting, highest purchase intent');

-- --------------------------------------------------------
-- Marketing Campaigns (10 rows)
-- I designed 10 distinct campaigns targeting different
-- product categories and customer segments so my ROI
-- and campaign performance queries return varied results.
-- --------------------------------------------------------
INSERT INTO MarketingCampaign (CampaignName, StartDate, EndDate, TotalBudget, CampaignObjective, TargetAgeMin, TargetAgeMax, TargetGender) VALUES
('June EOFY Blowout Sale',         '2025-06-01', '2025-06-30', 115000.00, 'Conversion',  18, 55, 'All'),
('Cold Weather Style Drop',        '2025-06-01', '2025-06-21',  48000.00, 'Awareness',   22, 48, 'Female'),
('Smart Home & Tech Clearance',    '2025-06-04', '2025-06-30',  62000.00, 'Conversion',  24, 52, 'Male'),
('Skincare & Fragrance Event',     '2025-06-01', '2025-06-14',  38000.00, 'Engagement',  18, 42, 'Female'),
('Refresh Your Home Sale',         '2025-06-09', '2025-06-30',  47000.00, 'Conversion',  30, 58, 'All'),
('Footwear & Sport Clearance',     '2025-06-05', '2025-06-25',  29000.00, 'Conversion',  18, 45, 'All'),
('Platinum Member Early Access',   '2025-06-01', '2025-06-03',  15000.00, 'Retention',   25, 60, 'All'),
('Mid-Year Brand Awareness Push',  '2025-06-15', '2025-06-30',  32000.00, 'Awareness',   18, 55, 'All'),
('Gen Z TikTok Activation',        '2025-06-08', '2025-06-22',  21000.00, 'Engagement',  16, 28, 'All'),
('Gift with Purchase Promotion',   '2025-06-10', '2025-06-24',  18000.00, 'Conversion',  25, 55, 'Female');


-- --------------------------------------------------------
-- Advertisements (15 rows)
-- I spread ads across all three main platforms and used
-- different ad formats (Reel, Carousel, Story, Post, Tweet)
-- so my ad type performance query returns all formats.
-- --------------------------------------------------------

INSERT INTO Advertisement (CampaignID, PlatformID, AdType, AdContent, PublishDate, BudgetAllocated, TotalImpressions) VALUES
(1, 1, 'Reel',     'June EOFY – Up to 55% off storewide. Limited time only!',           '2025-06-01', 19000.00, 410000),
(1, 2, 'Carousel', 'Our biggest June sale is here. Shop designer brands for less.',      '2025-06-01', 27000.00, 560000),
(1, 3, 'Tweet',    'Tax time treat yourself. EOFY savings on 1000s of styles.',          '2025-06-01',  9000.00, 140000),
(2, 1, 'Story',    'Cold season style sorted. New arrivals from Sportscraft and Oxford.','2025-06-02', 16000.00, 225000),
(2, 1, 'Post',     'Wrap up in luxury. Merino knitwear now 40% off at David Jones.',    '2025-06-05', 13000.00, 188000),
(2, 2, 'Carousel', 'Cold Weather Edit: Discover coats, knitwear and accessories.',      '2025-06-03', 19000.00, 308000),
(3, 2, 'Post',     'EOFY tech savings. Breville, Sony and Garmin at record prices.',    '2025-06-05', 23000.00, 365000),
(3, 3, 'Tweet',    'Upgrade your setup this EOFY. Big brand tech deals live now.',      '2025-06-06', 17000.00, 115000),
(3, 1, 'Reel',     'Smarter home. Better price. Shop DJ electronics this EOFY.',        '2025-06-07', 22000.00, 275000),
(4, 1, 'Story',    'Beauty Event – early access for DJ members. New arrivals inside.',  '2025-06-01', 13000.00, 205000),
(4, 1, 'Post',     'YSL, Kiehls, Charlotte Tilbury – all part of our beauty event.',   '2025-06-03', 14000.00, 192000),
(4, 2, 'Post',     'Treat yourself this EOFY. Shop the beauty event at davidjones.com.','2025-06-04', 11000.00, 245000),
(5, 2, 'Carousel', 'Refresh your home for less. Sheridan, Bambury and Vera Wang.',     '2025-06-10', 17000.00, 330000),
(5, 1, 'Reel',     'Your home. Reimagined. Up to 50% off homewares this EOFY.',        '2025-06-11', 16000.00, 255000),
(5, 3, 'Tweet',    'Home glow-up season. Big savings on homewares.',                    '2025-06-12',  7000.00,  72000);

-- --------------------------------------------------------
-- Website Sessions (35 rows)
-- I included a mix of devices, referral sources and bounce
-- flags to support device conversion and abandonment queries.
-- Mobile sessions outnumber desktop roughly 2:1 reflecting
-- real Australian e-commerce patterns.
-- --------------------------------------------------------

INSERT INTO WebsiteSession (CustomerID, SessionDate, SessionDuration, PagesViewed, DeviceType, ReferralSource, BounceFlag) VALUES
( 1, '2025-06-02 08:45:00', 510, 9,  'Mobile',  'Social-Instagram', 0),
( 2, '2025-06-02 10:55:00', 720, 14, 'Desktop', 'Social-Facebook',  0),
( 3, '2025-06-03 13:20:00', 175, 3,  'Mobile',  'Social-Instagram', 1),
( 4, '2025-06-03 15:50:00', 495, 8,  'Desktop', 'Organic',          0),
( 5, '2025-06-04 07:30:00', 340, 7,  'Mobile',  'Social-Instagram', 0),
( 6, '2025-06-04 09:40:00', 780, 15, 'Desktop', 'Email',            0),
( 7, '2025-06-05 12:00:00', 120, 2,  'Mobile',  'Social-X',         1),
( 8, '2025-06-05 14:55:00', 485, 8,  'Tablet',  'Social-Facebook',  0),
( 9, '2025-06-06 08:25:00', 225, 5,  'Mobile',  'Social-Instagram', 0),
(10, '2025-06-06 11:45:00', 605, 12, 'Desktop', 'Direct',           0),
(11, '2025-06-07 07:30:00', 870, 19, 'Desktop', 'Email',            0),
(12, '2025-06-07 10:40:00', 355, 6,  'Mobile',  'Social-Facebook',  0),
(13, '2025-06-08 14:10:00', 260, 5,  'Mobile',  'Social-Instagram', 0),
(14, '2025-06-08 15:35:00', 105, 2,  'Mobile',  'Social-X',         1),
(15, '2025-06-09 08:30:00', 695, 14, 'Desktop', 'Social-Facebook',  0),
(16, '2025-06-09 10:00:00', 140, 3,  'Mobile',  'Organic',          1),
(17, '2025-06-10 12:15:00', 745, 16, 'Desktop', 'Email',            0),
(18, '2025-06-10 14:50:00', 300, 6,  'Mobile',  'Social-Instagram', 0),
(19, '2025-06-11 08:10:00', 415, 9,  'Tablet',  'Social-Facebook',  0),
(20, '2025-06-11 10:30:00', 190, 4,  'Mobile',  'Social-X',         0),
(21, '2025-06-12 09:00:00', 565, 11, 'Desktop', 'Email',            0),
(22, '2025-06-12 13:30:00', 325, 7,  'Mobile',  'Social-Instagram', 0),
(23, '2025-06-13 09:50:00', 150, 3,  'Mobile',  'Social-X',         1),
(24, '2025-06-13 11:55:00', 500, 10, 'Desktop', 'Direct',           0),
(25, '2025-06-14 08:45:00', 640, 13, 'Desktop', 'Social-Facebook',  0),
( 1, '2025-06-15 10:20:00', 420, 8,  'Mobile',  'Social-Instagram', 0),
( 2, '2025-06-16 13:45:00', 555, 11, 'Desktop', 'Email',            0),
( 5, '2025-06-17 08:30:00', 285, 5,  'Mobile',  'Social-Instagram', 0),
(11, '2025-06-18 09:50:00', 510, 10, 'Desktop', 'Social-Facebook',  0),
(15, '2025-06-19 13:05:00', 375, 7,  'Mobile',  'Direct',           0),
( 6, '2025-06-20 08:20:00', 625, 12, 'Desktop', 'Email',            0),
(21, '2025-06-21 11:00:00', 305, 6,  'Mobile',  'Social-Instagram', 0),
(24, '2025-06-22 13:30:00', 470, 9,  'Desktop', 'Social-Facebook',  0),
(17, '2025-06-23 08:55:00', 715, 15, 'Desktop', 'Email',            0),
(10, '2025-06-24 14:30:00', 345, 7,  'Mobile',  'Social-Instagram', 0);

-- --------------------------------------------------------
-- Customer Orders (28 rows)
-- I set IsEOFYSale = 1 for all orders since they all fall
-- within the June 2025 campaign window. This flag lets me
-- instantly filter sale-period orders in all my queries.
-- --------------------------------------------------------

INSERT INTO CustomerOrder (CustomerID, SessionID, OrderDate, TotalAmount, DiscountApplied, PaymentMethod, OrderStatus, IsEOFYSale) VALUES
( 1,  1, '2025-06-02 09:22:00',  388.00,  70.00, 'Credit Card', 'Completed', 1),
( 2,  2, '2025-06-02 11:40:00',  768.00, 130.00, 'PayPal',      'Completed', 1),
( 5,  5, '2025-06-04 08:05:00',  174.00,  45.00, 'Credit Card', 'Completed', 1),
( 6,  6, '2025-06-04 10:25:00', 1398.00, 260.00, 'AMEX',        'Completed', 1),
( 8,  8, '2025-06-05 15:45:00',  363.00,  92.00, 'Credit Card', 'Completed', 1),
( 9,  9, '2025-06-06 09:10:00',   45.00,  10.00, 'Credit Card', 'Completed', 1),
(10, 10, '2025-06-06 12:30:00',  978.00, 210.00, 'PayPal',      'Completed', 1),
(11, 11, '2025-06-07 08:05:00', 1528.00, 320.00, 'AMEX',        'Completed', 1),
(12, 12, '2025-06-07 11:20:00',  314.00,  65.00, 'Credit Card', 'Completed', 1),
(13, 13, '2025-06-08 14:50:00',  164.00,  55.00, 'Credit Card', 'Completed', 1),
(15, 15, '2025-06-09 09:05:00',  484.00,  35.00, 'PayPal',      'Completed', 1),
(17, 17, '2025-06-10 12:55:00',  658.00, 155.00, 'Credit Card', 'Completed', 1),
(18, 18, '2025-06-10 15:20:00',  209.00,  60.00, 'Credit Card', 'Completed', 1),
(19, 19, '2025-06-11 08:45:00',  348.00,  75.00, 'PayPal',      'Completed', 1),
(20, 20, '2025-06-11 11:05:00',   99.00,  10.00, 'Credit Card', 'Completed', 1),
(21, 21, '2025-06-12 09:30:00',  808.00, 170.00, 'AMEX',        'Completed', 1),
(22, 22, '2025-06-12 14:10:00',  238.00,  46.00, 'Credit Card', 'Completed', 1),
(24, 24, '2025-06-13 12:40:00',  648.00, 130.00, 'PayPal',      'Completed', 1),
(25, 25, '2025-06-14 09:15:00',  398.00,  70.00, 'Credit Card', 'Completed', 1),
( 1, 26, '2025-06-15 10:55:00',  254.00,  75.00, 'Credit Card', 'Completed', 1),
( 2, 27, '2025-06-16 14:20:00',  549.00, 210.00, 'PayPal',      'Completed', 1),
( 5, 28, '2025-06-17 09:00:00',  174.00,  45.00, 'Credit Card', 'Completed', 1),
(11, 29, '2025-06-18 10:15:00',  299.00,  85.00, 'AMEX',        'Completed', 1),
(15, 30, '2025-06-19 13:30:00',  109.00,  30.00, 'Credit Card', 'Completed', 1),
( 6, 31, '2025-06-20 08:50:00',  958.00, 220.00, 'AMEX',        'Completed', 1),
(21, 32, '2025-06-21 11:25:00',  222.00,  48.00, 'Credit Card', 'Completed', 1),
(24, 33, '2025-06-22 13:55:00',  459.00, 105.00, 'PayPal',      'Completed', 1),
(17, 34, '2025-06-23 09:20:00',  518.00, 125.00, 'Credit Card', 'Completed', 1);

-- --------------------------------------------------------
-- Order Items (61 rows)
-- I included multiple items per order to reflect realistic
-- shopping behaviour and support category-level analysis.
-- --------------------------------------------------------

INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice, DiscountPercent) VALUES
( 1,  1, 1, 209.00, 40.11),
( 1, 20, 2,  42.00, 39.13),
( 2,  2, 1, 319.00, 41.89),
( 2,  7, 1, 229.00, 49.00),
( 2, 17, 1,  99.00, 44.69),
( 3, 10, 2,  99.00, 33.56),
( 4,  6, 1, 279.00, 30.20),
( 4,  8, 1, 549.00, 31.29),
( 5,  3, 1,  79.00, 39.23),
( 5,  4, 2,  95.00, 40.25),
( 5, 12, 1,  45.00, 43.00),
( 6, 12, 1,  45.00, 43.00),
( 7,  6, 1, 279.00, 30.20),
( 7, 11, 1,  65.00, 31.58),
( 7, 18, 2,  59.00, 33.71),
( 8,  6, 1, 279.00, 30.20),
( 8,  5, 1, 155.00, 26.19),
( 8, 19, 1, 169.00, 32.13),
( 9,  4, 1,  95.00, 40.25),
( 9, 13, 1,  99.00, 41.42),
(10,  7, 1, 229.00, 49.00),
(10, 14, 1, 149.00, 50.17),
(11, 18, 1,  59.00, 33.71),
(12, 11, 1,  65.00, 31.58),
(12, 20, 2,  42.00, 39.13),
(13,  9, 1,  45.00, 43.00),
(13, 16, 1, 109.00, 42.33),
(14, 17, 1,  99.00, 44.69),
(15,  5, 1, 155.00, 26.19),
(15,  1, 1, 209.00, 40.11);
INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice, DiscountPercent) VALUES
(16,  2, 1, 319.00, 41.89),
(16, 13, 1,  99.00, 41.42),
(17,  3, 1,  79.00, 39.23),
(17,  4, 1,  95.00, 40.25),
(17, 20, 1,  42.00, 39.13),
(18, 10, 1,  99.00, 33.56),
(18, 12, 2,  45.00, 43.00),
(19,  8, 1, 549.00, 31.29),
(20, 16, 1, 109.00, 42.33),
(20, 20, 2,  42.00, 39.13),
(21,  7, 1, 229.00, 49.00),
(21, 20, 1,  42.00, 39.13),
(22,  2, 1, 319.00, 41.89),
(22, 11, 1,  65.00, 31.58),
(22,  8, 1, 549.00, 31.29),
(23,  6, 1, 279.00, 30.20),
(23, 18, 1,  59.00, 33.71),
(24, 16, 1, 109.00, 42.33),
(25,  8, 1, 549.00, 31.29),
(25,  5, 1, 155.00, 26.19),
(25, 17, 1,  99.00, 44.69),
(25, 20, 1,  42.00, 39.13),
(26, 13, 1,  99.00, 41.42),
(26, 12, 1,  45.00, 43.00),
(26, 20, 2,  42.00, 39.13),
(26,  9, 1,  45.00, 43.00),
(27, 15, 1, 349.00, 30.06),
(27,  3, 1,  79.00, 39.23),
(28,  2, 1, 319.00, 41.89),
(28, 10, 1,  99.00, 33.56),
(28, 20, 1,  42.00, 39.13);
-- --------------------------------------------------------
-- Ad Interactions (60 rows)
-- I store Impressions, Clicks, Likes, and Shares to enable
-- full CTR calculation. The ConvertedToOrder flag and
-- linked OrderID allow me to trace purchases back to the
-- specific ad that drove the conversion.
-- Note: CustomerID 33 fixed to 15 (valid customer).
-- --------------------------------------------------------
 
INSERT INTO AdInteraction (AdID, CustomerID, InteractionDate, InteractionType, ConvertedToOrder, OrderID) VALUES
( 1,  1, '2025-06-01 17:30:00', 'Impression', 0, NULL),
( 1,  1, '2025-06-01 17:38:00', 'Click',      1,  1),
( 1,  3, '2025-06-01 18:55:00', 'Impression', 0, NULL),
( 1,  5, '2025-06-02 07:15:00', 'Click',      1,  3),
( 1,  9, '2025-06-02 08:15:00', 'Click',      1,  6),
( 1, 13, '2025-06-03 09:30:00', 'Like',       0, NULL),
( 1, 18, '2025-06-04 11:25:00', 'Click',      1, 13),
( 1, 22, '2025-06-05 13:40:00', 'Like',       0, NULL),
( 2,  2, '2025-06-01 19:45:00', 'Click',      1,  2),
( 2,  6, '2025-06-02 09:30:00', 'Click',      1,  4),
( 2,  8, '2025-06-03 14:20:00', 'Click',      1,  5),
( 2, 10, '2025-06-04 10:30:00', 'Click',      1,  7),
( 2, 12, '2025-06-05 12:15:00', 'Click',      1,  9),
( 2, 15, '2025-06-06 08:30:00', 'Click',      1, 11),
( 2, 19, '2025-06-07 13:20:00', 'Like',       0, NULL),
( 2, 20, '2025-06-08 09:30:00', 'Impression', 0, NULL),
( 3,  7, '2025-06-02 07:40:00', 'Impression', 0, NULL),
( 3, 14, '2025-06-03 08:25:00', 'Click',      0, NULL),
( 3, 20, '2025-06-04 10:25:00', 'Click',      1, 15),
( 3, 23, '2025-06-05 12:40:00', 'Impression', 0, NULL),
( 4,  1, '2025-06-02 06:55:00', 'Click',      0, NULL),
( 4,  3, '2025-06-03 13:15:00', 'Click',      0, NULL),
( 4,  5, '2025-06-04 07:25:00', 'Impression', 0, NULL),
( 4, 11, '2025-06-06 08:30:00', 'Click',      1,  8),
( 4, 17, '2025-06-08 12:10:00', 'Click',      1, 12),
( 5, 13, '2025-06-05 09:45:00', 'Like',       0, NULL),
( 5, 22, '2025-06-06 11:30:00', 'Click',      1, 17),
( 5, 25, '2025-06-07 08:45:00', 'Click',      1, 19),
( 6,  2, '2025-06-04 10:30:00', 'Like',       0, NULL),
( 6,  8, '2025-06-05 13:45:00', 'Share',      0, NULL),
( 6, 15, '2025-06-06 08:25:00', 'Click',      0, NULL),
( 6, 21, '2025-06-09 09:30:00', 'Click',      1, 16),
( 7,  4, '2025-06-05 09:30:00', 'Impression', 0, NULL),
( 7, 10, '2025-06-06 11:40:00', 'Click',      1,  7),
( 7, 24, '2025-06-07 13:20:00', 'Click',      1, 18),
( 7, 25, '2025-06-08 08:30:00', 'Like',       0, NULL),
( 8,  4, '2025-06-06 07:35:00', 'Click',      0, NULL),
( 8, 14, '2025-06-07 09:30:00', 'Impression', 0, NULL),
( 8, 23, '2025-06-08 11:25:00', 'Click',      0, NULL),
( 9,  6, '2025-06-08 10:30:00', 'Click',      1,  4),
( 9, 17, '2025-06-09 12:20:00', 'Click',      1, 12),
( 9, 21, '2025-06-10 08:35:00', 'Like',       0, NULL),
(10,  1, '2025-06-01 16:30:00', 'Click',      0, NULL),
(10,  3, '2025-06-02 08:25:00', 'Click',      0, NULL),
(10, 13, '2025-06-03 10:30:00', 'Click',      1, 10),
(10, 22, '2025-06-04 13:30:00', 'Click',      1, 17),
(11,  5, '2025-06-04 07:35:00', 'Like',       0, NULL),
(11, 15, '2025-06-05 09:25:00', 'Click',      0, NULL),
(11, 19, '2025-06-06 11:30:00', 'Click',      0, NULL),
(12,  6, '2025-06-05 08:30:00', 'Click',      1,  4),
(12, 11, '2025-06-06 10:30:00', 'Click',      1,  8),
(12, 17, '2025-06-07 12:25:00', 'Click',      1, 12),
(13,  2, '2025-06-11 09:25:00', 'Click',      1, 21),
(13, 24, '2025-06-12 11:30:00', 'Click',      1, 27),
(13, 25, '2025-06-13 13:20:00', 'Click',      1, 19),
(14, 18, '2025-06-12 08:30:00', 'Click',      1, 13),
(14, 22, '2025-06-13 10:30:00', 'Like',       0, NULL),
(14, 15, '2025-06-14 12:30:00', 'Impression', 0, NULL),
(15, 20, '2025-06-13 09:30:00', 'Click',      0, NULL),
(15, 23, '2025-06-14 11:25:00', 'Impression', 0, NULL);

-- --------------------------------------------------------
-- Product Reviews (22 rows)
-- I included a mix of ratings (3, 4 and 5 stars) to make
-- the review data realistic and support sentiment analysis.
-- --------------------------------------------------------
INSERT INTO ProductReview (ProductID, CustomerID, Rating, ReviewText, ReviewDate) VALUES
( 1,  1, 5, 'Absolutely stunning bag. The leather quality is top notch and the EOFY price was unbeatable.',  '2025-06-11'),
( 2,  2, 4, 'The Sportscraft blazer is beautifully tailored. Runs slightly slim so size up if unsure.',      '2025-06-13'),
( 3,  5, 5, 'These Converse are so comfortable straight out of the box. Wearing them constantly.',            '2025-06-09'),
( 5, 15, 5, 'The YSL fragrance is divine. Long-lasting and I get compliments every time I wear it.',         '2025-06-15'),
( 8,  6, 5, 'Best espresso machine I have ever owned. Makes cafe-quality coffee every single morning.',      '2025-06-12'),
( 7,  2, 4, 'The Sheridan sheets are incredibly soft. High quality and worth every cent at sale price.',     '2025-06-16'),
( 8, 24, 4, 'Love the Breville machine. Setup was straightforward and the coffee is exceptional.',           '2025-06-21'),
(10,  3, 3, 'Good quality tights but the waistband is a little tight. May need to size up.',                 '2025-06-10'),
(11, 11, 5, 'The Kiehls serum is incredible. My skin has genuinely improved in just two weeks.',             '2025-06-17'),
(12,  9, 4, 'Love the cat-eye frame. UV protection is solid and the EOFY price was great.',                  '2025-06-14'),
(13, 22, 5, 'Most comfortable sweater I own. Washed beautifully and the colour is exactly as pictured.',     '2025-06-19'),
(14, 19, 3, 'Nice looking dinnerware but one bowl arrived chipped. Replacement arrived quickly though.',     '2025-06-20'),
(15, 10, 5, 'The Garmin tracker is exceptional. Battery lasts ages and the health tracking is very accurate.','2025-06-16'),
(17,  8, 4, 'The merino throw is so soft and warm. Makes the living room look really luxurious.',            '2025-06-15'),
(18, 13, 4, 'Great foundation with excellent coverage. Shade matched perfectly with the in-store tester.',   '2025-06-12'),
(19, 20, 5, 'These Asics trail shoes are phenomenal. Incredible grip and so comfortable on long runs.',      '2025-06-17'),
(20,  1, 5, 'The jasmine and oud candle smells amazing. Has completely transformed my lounge room.',         '2025-06-13'),
( 4, 18, 4, 'Really well-cut linen trousers. Breathable and perfect for the office.',                        '2025-06-14'),
( 9, 12, 3, 'Nice silk pocket square but the colour was slightly different from the website photo.',         '2025-06-18'),
(16,  6, 5, 'These Calvin Klein pyjamas are ridiculously comfortable. Will definitely buy more colours.',    '2025-06-21'),
( 7, 25, 4, 'The sheets are very high quality. Delivery was prompt and the packaging was impressive.',       '2025-06-22'),
( 2, 17, 5, 'Absolutely love this blazer. Perfect for Melbourne winters and works for both work and weekends.','2025-06-19');

-- --------------------------------------------------------
-- CampaignTouchpoint (14 rows)
-- I mapped real customer journeys based on the session and
-- ad interaction data I already have, showing the multi-step
-- path from awareness to purchase for selected customers.
-- --------------------------------------------------------

INSERT INTO CampaignTouchpoint (CustomerID, CampaignID, TouchpointDate, TouchpointStage, Channel, Notes) VALUES
-- Customer 1 (Zara, Platinum) – full purchase journey via EOFY campaign
(1, 1, '2025-06-01 17:30:00', 'Awareness',     'Instagram', 'Viewed EOFY Reel ad on Instagram feed'),
(1, 1, '2025-06-02 08:45:00', 'Consideration', 'Website',   'Browsed accessories and home categories'),
(1, 1, '2025-06-02 09:05:00', 'Cart',          'Website',   'Added shoulder bag and candle to cart'),
(1, 1, '2025-06-02 09:22:00', 'Purchase',      'Website',   'Completed order – $388 via Credit Card'),
-- Customer 2 (Marcus, Gold) – full journey via Facebook carousel
(2, 1, '2025-06-01 19:45:00', 'Awareness',     'Facebook',  'Engaged with EOFY Carousel ad on Facebook'),
(2, 1, '2025-06-02 10:55:00', 'Consideration', 'Website',   'Browsed clothing and home categories'),
(2, 1, '2025-06-02 11:40:00', 'Purchase',      'Website',   'Completed order – $768 via PayPal'),
-- Customer 3 (Priya, Silver) – awareness only, did not convert
(3, 4, '2025-06-03 13:15:00', 'Awareness',     'Instagram', 'Clicked beauty event Story ad'),
(3, 4, '2025-06-03 13:20:00', 'Consideration', 'Website',   'Browsed skincare products briefly'),
(3, 4, '2025-06-03 13:45:00', 'Retargeting',   'Instagram', 'Received follow-up ad but did not convert'),
-- Customer 11 (Sabrina, Platinum) – cart then purchased
(11, 1, '2025-06-06 09:00:00', 'Awareness',     'Email',    'Opened EOFY email campaign'),
(11, 1, '2025-06-07 07:30:00', 'Consideration', 'Website',  'Long session – 19 pages viewed'),
(11, 1, '2025-06-07 08:00:00', 'Cart',          'Website',  'Added electronics and beauty to cart'),
(11, 1, '2025-06-07 08:05:00', 'Purchase',      'Website',  'Completed order – $1528 via AMEX');


-- ============================================================
-- PART B: ANALYTICAL QUERIES FOR CMO DECISION SUPPORT
--
-- I formulated 10 queries to address key business issues
-- I identified as CMO. Each query targets a specific
-- decision the marketing team needs to make for the
-- EOFY 2025 campaign and future campaigns.
-- ============================================================
 
 
-- -------------------------------------------------------
-- Q1: Social Media Platform CTR Analysis
-- Business Issue: Which platform drives the most qualified
-- traffic from our EOFY ads?
-- I calculate CTR using the actual TotalImpressions stored
-- on each Advertisement record (which reflects the platform's
-- reported delivery numbers) divided by the click count from
-- AdInteraction. This is more accurate than counting
-- impression rows which may be sampled.
-- -------------------------------------------------------
-- I pre-aggregate at the ad level first using a derived table (ad_summary)
-- so that TotalImpressions from Advertisement and click/conversion counts
-- from AdInteraction are computed separately before being joined.
-- This avoids the duplication problem where joining AdInteraction directly
-- to Advertisement would multiply TotalImpressions by the number of interactions.
SELECT
    sp.PlatformName,
    SUM(ad_summary.TotalImpressions)    AS TotalImpressions,
    SUM(ad_summary.TotalClicks)         AS TotalClicks,
    SUM(ad_summary.ConvertedPurchases)  AS ConvertedPurchases,
    ROUND(
        SUM(ad_summary.TotalClicks) * 100.0
        / NULLIF(SUM(ad_summary.TotalImpressions), 0),
    4)                                  AS CTR_Percent,
    ROUND(
        SUM(ad_summary.ConvertedPurchases) * 100.0
        / NULLIF(SUM(ad_summary.TotalClicks), 0),
    2)                                  AS ConversionRate_Percent
FROM (
    -- Inner query: aggregate clicks and conversions at the individual ad level
    -- I group by AdID so TotalImpressions is counted exactly once per ad
    SELECT
        ad.AdID,
        ad.PlatformID,
        ad.TotalImpressions,
        COUNT(CASE WHEN ai.InteractionType = 'Click' THEN 1 END) AS TotalClicks,
        COUNT(CASE WHEN ai.ConvertedToOrder = 1      THEN 1 END) AS ConvertedPurchases
    FROM Advertisement ad
    LEFT JOIN AdInteraction ai ON ad.AdID = ai.AdID
    GROUP BY ad.AdID, ad.PlatformID, ad.TotalImpressions
) ad_summary
JOIN SocialMediaPlatform sp ON ad_summary.PlatformID = sp.PlatformID
GROUP BY sp.PlatformName
ORDER BY CTR_Percent DESC;
 
 
-- -------------------------------------------------------
-- Q2: Campaign ROI – Revenue vs Budget
-- Business Issue: Are our campaigns generating sufficient
-- return on marketing investment?
-- I link orders back to campaigns through the AdInteraction
-- conversion bridge to ensure only ad-attributed revenue
-- is counted against each campaign budget.
-- -------------------------------------------------------
SELECT
    mc.CampaignName,
    mc.TotalBudget,
    SUM(co.TotalAmount)                                       AS TotalRevenue,
    ROUND(SUM(co.TotalAmount) - mc.TotalBudget, 2)           AS NetReturn,
    ROUND((SUM(co.TotalAmount) / mc.TotalBudget) * 100, 2)   AS ROI_Percent
FROM CustomerOrder co
JOIN WebsiteSession  ws ON co.SessionID    = ws.SessionID
JOIN AdInteraction   ai ON ai.CustomerID   = co.CustomerID
    AND ai.ConvertedToOrder = 1
    AND ai.OrderID = co.OrderID
JOIN Advertisement   ad ON ai.AdID         = ad.AdID
JOIN MarketingCampaign mc ON ad.CampaignID = mc.CampaignID
WHERE co.IsEOFYSale = 1
GROUP BY mc.CampaignID, mc.CampaignName, mc.TotalBudget
ORDER BY ROI_Percent DESC;
 
 
-- -------------------------------------------------------
-- Q3: Top-Selling Product Categories During EOFY
-- Business Issue: Which categories are the strongest EOFY
-- performers and should receive more ad spend next year?
-- -------------------------------------------------------
SELECT
    c.CategoryName,
    COUNT(DISTINCT co.OrderID)                        AS TotalOrders,
    SUM(oi.Quantity)                                  AS UnitsSold,
    ROUND(SUM(oi.Quantity * oi.UnitPrice), 2)         AS GrossRevenue,
    ROUND(AVG(oi.DiscountPercent), 2)                 AS AvgDiscountPercent
FROM OrderItem oi
JOIN Product       p  ON oi.ProductID = p.ProductID
JOIN Category      c  ON p.CategoryID = c.CategoryID
JOIN CustomerOrder co ON oi.OrderID   = co.OrderID
WHERE co.IsEOFYSale = 1
GROUP BY c.CategoryName
ORDER BY GrossRevenue DESC;
 
 
-- -------------------------------------------------------
-- Q4: Device Type vs Conversion Rate
-- Business Issue: Should we prioritise mobile-first
-- creative to capture on-the-go shoppers?
-- I use LEFT JOIN so sessions without orders are still
-- counted in the denominator for an accurate rate.
-- -------------------------------------------------------
SELECT
    ws.DeviceType,
    COUNT(DISTINCT ws.SessionID)                                  AS TotalSessions,
    COUNT(DISTINCT co.OrderID)                                    AS TotalConversions,
    ROUND(COUNT(DISTINCT co.OrderID) * 100.0
          / NULLIF(COUNT(DISTINCT ws.SessionID), 0), 2)           AS ConversionRate_Percent,
    ROUND(AVG(co.TotalAmount), 2)                                 AS AvgOrderValue
FROM WebsiteSession ws
LEFT JOIN CustomerOrder co ON ws.SessionID = co.SessionID
    AND co.IsEOFYSale = 1
GROUP BY ws.DeviceType
ORDER BY ConversionRate_Percent DESC;
 
 
-- -------------------------------------------------------
-- Q5: Membership Tier Engagement and Spend
-- Business Issue: Are loyalty members generating higher
-- value? Should we target them exclusively in retargeting?
-- I use FIELD() to force a logical tier order in results.
-- -------------------------------------------------------
SELECT
    c.MembershipTier,
    COUNT(DISTINCT c.CustomerID)                                         AS CustomerCount,
    COUNT(DISTINCT co.OrderID)                                           AS TotalOrders,
    ROUND(SUM(co.TotalAmount), 2)                                        AS TotalRevenue,
    ROUND(AVG(co.TotalAmount), 2)                                        AS AvgOrderValue,
    ROUND(SUM(co.TotalAmount) / NULLIF(COUNT(DISTINCT c.CustomerID), 0), 2) AS RevenuePerCustomer
FROM Customer c
LEFT JOIN CustomerOrder co ON c.CustomerID = co.CustomerID
    AND co.IsEOFYSale = 1
GROUP BY c.MembershipTier
ORDER BY FIELD(c.MembershipTier, 'Platinum', 'Gold', 'Silver', 'Bronze');
 
 
-- -------------------------------------------------------
-- Q6: Referral Source Impact on Average Order Value
-- Business Issue: Does social media traffic convert at
-- higher AOV than organic or direct traffic?
-- -------------------------------------------------------
SELECT
    ws.ReferralSource,
    COUNT(DISTINCT ws.SessionID)                       AS Sessions,
    COUNT(DISTINCT co.OrderID)                         AS Orders,
    ROUND(AVG(co.TotalAmount), 2)                      AS AvgOrderValue,
    ROUND(AVG(ws.SessionDuration) / 60.0, 1)           AS AvgSessionMinutes,
    ROUND(AVG(ws.PagesViewed), 1)                      AS AvgPagesViewed
FROM WebsiteSession ws
LEFT JOIN CustomerOrder co ON ws.SessionID = co.SessionID
    AND co.IsEOFYSale = 1
GROUP BY ws.ReferralSource
ORDER BY AvgOrderValue DESC;


-- -------------------------------------------------------
-- Q7: Ad Format Performance by Conversion
-- Business Issue: Which creative formats (Reel, Carousel,
-- Story, Post) drive the most sales and lowest cost
-- per conversion?
-- -------------------------------------------------------
SELECT
    ad_summary.AdType,
    sp.PlatformName,
    SUM(ad_summary.TotalClicks)       AS TotalClicks,
    SUM(ad_summary.TotalConversions)  AS PurchaseConversions,
    ROUND(SUM(ad_summary.TotalConversions)*100.0
        /NULLIF(SUM(ad_summary.TotalClicks),0),2) AS ClickToConversionRate,
    SUM(ad_summary.BudgetAllocated)   AS BudgetSpent,
    ROUND(SUM(ad_summary.BudgetAllocated)
        /NULLIF(SUM(ad_summary.TotalConversions),0),2) AS CostPerConversion
FROM (
    SELECT
        ad.AdID, ad.AdType, ad.PlatformID, ad.BudgetAllocated,
        COUNT(CASE WHEN ai.InteractionType='Click' THEN 1 END) AS TotalClicks,
        COUNT(CASE WHEN ai.ConvertedToOrder=1 THEN 1 END) AS TotalConversions
    FROM Advertisement ad
    LEFT JOIN AdInteraction ai ON ad.AdID=ai.AdID
    GROUP BY ad.AdID, ad.AdType, ad.PlatformID, ad.BudgetAllocated
) ad_summary
JOIN SocialMediaPlatform sp ON ad_summary.PlatformID=sp.PlatformID
GROUP BY ad_summary.AdType, sp.PlatformName
ORDER BY ClickToConversionRate DESC;
-- -------------------------------------------------------
-- Q8: New vs Returning Customer Revenue Split
-- Business Issue: Is the EOFY campaign attracting new
-- customers or mainly rewarding existing ones?
-- I use RegistrationDate as a cohort proxy to segment
-- customers by their relationship vintage.
-- -------------------------------------------------------
SELECT
    CASE
        WHEN c.RegistrationDate >= '2025-01-01' THEN 'New Customer (2025)'
        WHEN c.RegistrationDate >= '2023-01-01' THEN 'Recent Customer (2023-24)'
        ELSE 'Loyal Customer (pre-2023)'
    END                              AS CustomerSegment,
    COUNT(DISTINCT c.CustomerID)    AS CustomerCount,
    COUNT(DISTINCT co.OrderID)      AS TotalOrders,
    ROUND(SUM(co.TotalAmount), 2)   AS TotalRevenue,
    ROUND(AVG(co.TotalAmount), 2)   AS AvgOrderValue
FROM Customer c
JOIN CustomerOrder co ON c.CustomerID = co.CustomerID
WHERE co.IsEOFYSale = 1
GROUP BY CustomerSegment
ORDER BY TotalRevenue DESC;
 
 
-- -------------------------------------------------------
-- Q9: Geographic Revenue by State
-- Business Issue: Are there under-served states where
-- targeted geo ads could grow EOFY sales?
-- -------------------------------------------------------
SELECT
    c.State,
    COUNT(DISTINCT c.CustomerID)    AS UniqueCustomers,
    COUNT(DISTINCT co.OrderID)      AS TotalOrders,
    ROUND(SUM(co.TotalAmount), 2)   AS TotalRevenue,
    ROUND(AVG(co.TotalAmount), 2)   AS AvgOrderValue
FROM Customer c
JOIN CustomerOrder co ON c.CustomerID = co.CustomerID
WHERE co.IsEOFYSale = 1
GROUP BY c.State
ORDER BY TotalRevenue DESC;
 
 
-- -------------------------------------------------------
-- Q10: Session Abandonment Analysis
-- Business Issue: Which high-engagement sessions did NOT
-- convert? This helps identify checkout friction issues.
-- I filter for sessions with 4+ pages viewed and no bounce
-- to isolate genuine purchase-intent abandonment.
-- -------------------------------------------------------
SELECT
    ws.DeviceType,
    ws.ReferralSource,
    COUNT(ws.SessionID)                          AS AbandonedSessions,
    ROUND(AVG(ws.SessionDuration) / 60.0, 1)    AS AvgMinutesSpent,
    ROUND(AVG(ws.PagesViewed), 1)               AS AvgPagesViewed
FROM WebsiteSession ws
LEFT JOIN CustomerOrder co ON ws.SessionID = co.SessionID
WHERE co.OrderID IS NULL
  AND ws.PagesViewed >= 4
  AND ws.BounceFlag = 0
GROUP BY ws.DeviceType, ws.ReferralSource
ORDER BY AbandonedSessions DESC;
 
 
-- -------------------------------------------------------
-- Supplementary Query: Customer Journey Funnel Analysis
-- Business Issue: At which stage of the funnel do most
-- customers drop off before purchasing?
-- I use the CampaignTouchpoint table to analyse the
-- multi-step customer journey. This query shows how many
-- customers reached each stage and the conversion rate
-- from Awareness through to Purchase.
-- -------------------------------------------------------
SELECT
    TouchpointStage,
    COUNT(DISTINCT CustomerID)   AS CustomersAtStage,
    ROUND(
        COUNT(DISTINCT CustomerID) * 100.0
        / NULLIF((SELECT COUNT(DISTINCT CustomerID)
                  FROM CampaignTouchpoint
                  WHERE TouchpointStage = 'Awareness'), 0),
    1)                           AS FunnelRetention_Percent
FROM CampaignTouchpoint
GROUP BY TouchpointStage
ORDER BY FIELD(TouchpointStage,
    'Awareness','Consideration','Cart','Purchase','Retargeting');
 
 
-- -------------------------------------------------------
-- CustomerJourneySummary View Query
-- I can query my view directly to see which customers
-- completed the full journey vs dropped off mid-funnel.
-- -------------------------------------------------------
SELECT * FROM CustomerJourneySummary
ORDER BY TotalTouchpoints DESC;




