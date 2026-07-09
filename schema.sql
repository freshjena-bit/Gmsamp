-- =====================================================
--  INFERNO RP - MySQL Schema
--  Database: s696_GadaLuBau
--  Engine: InnoDB (utf8mb4)
-- =====================================================

-- Tabel pemain utama
CREATE TABLE IF NOT EXISTS `players` (
    `id`              INT(11) NOT NULL AUTO_INCREMENT,
    `name`            VARCHAR(24) NOT NULL,
    `password`        VARCHAR(129) NOT NULL,
    `salt`            VARCHAR(32) NOT NULL,
    `ip`              VARCHAR(45) NOT NULL DEFAULT '',
    `cash`            INT(11) NOT NULL DEFAULT 5000,
    `bank`            BIGINT(20) NOT NULL DEFAULT 25000,
    `debt`            BIGINT(20) NOT NULL DEFAULT 0,
    `credit_limit`    INT(11) NOT NULL DEFAULT 0,
    `credit_used`     INT(11) NOT NULL DEFAULT 0,
    `level`           INT(11) NOT NULL DEFAULT 1,
    `exp`             INT(11) NOT NULL DEFAULT 0,
    `admin_level`     TINYINT(1) NOT NULL DEFAULT 0,
    `skin`            INT(11) NOT NULL DEFAULT 0,
    `age`             TINYINT(2) NOT NULL DEFAULT 17,
    `gender`          TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0=laki, 1=perempuan',
    `health`          FLOAT NOT NULL DEFAULT 100.0,
    `armor`           FLOAT NOT NULL DEFAULT 0.0,
    `hunger`          FLOAT NOT NULL DEFAULT 100.0,
    `thirst`          FLOAT NOT NULL DEFAULT 100.0,
    `sleep`           FLOAT NOT NULL DEFAULT 100.0,
    `stamina`         FLOAT NOT NULL DEFAULT 100.0,
    `sickness`        TINYINT(2) NOT NULL DEFAULT 0 COMMENT '0=sehat,1=flu,2=demam,3=diare,4=infeksi',
    `sick_time`       INT(11) NOT NULL DEFAULT 0,
    `pos_x`           FLOAT NOT NULL DEFAULT 1743.20,
    `pos_y`           FLOAT NOT NULL DEFAULT -1862.05,
    `pos_z`           FLOAT NOT NULL DEFAULT 13.58,
    `pos_a`           FLOAT NOT NULL DEFAULT 270.0,
    `interior`        INT(11) NOT NULL DEFAULT 0,
    `virtualworld`    INT(11) NOT NULL DEFAULT 0,
    `wanted`          TINYINT(2) NOT NULL DEFAULT 0,
    `job`             INT(11) NOT NULL DEFAULT 0,
    `faction`         INT(11) NOT NULL DEFAULT 0 COMMENT '0=none,1=SAPD,2=SAGS,3=SAMD,4=SANEW',
    `faction_rank`    INT(11) NOT NULL DEFAULT 0,
    `phone`           INT(11) NOT NULL DEFAULT 0,
    `phone_credit`    INT(11) NOT NULL DEFAULT 0,
    `phone_data`      INT(11) NOT NULL DEFAULT 0,
    `ktp`             TINYINT(1) NOT NULL DEFAULT 0,
    `kk`              TINYINT(1) NOT NULL DEFAULT 0,
    `sim`             TINYINT(1) NOT NULL DEFAULT 0,
    `stnk`            TINYINT(1) NOT NULL DEFAULT 0,
    `bpkb`            TINYINT(1) NOT NULL DEFAULT 0,
    `paspor`          TINYINT(1) NOT NULL DEFAULT 0,
    `sis`             TINYINT(1) NOT NULL DEFAULT 0,
    `drive_lic`       TINYINT(1) NOT NULL DEFAULT 0,
    `weapon_lic`      TINYINT(1) NOT NULL DEFAULT 0,
    `bank_rek`        INT(11) NOT NULL DEFAULT 0,
    `kpr`             INT(11) NOT NULL DEFAULT 0,
    `kkb`             INT(11) NOT NULL DEFAULT 0,
    `kta`             INT(11) NOT NULL DEFAULT 0,
    `jail`            TINYINT(1) NOT NULL DEFAULT 0,
    `jail_time`       INT(11) NOT NULL DEFAULT 0,
    `arrest`          TINYINT(1) NOT NULL DEFAULT 0,
    `arrest_time`     INT(11) NOT NULL DEFAULT 0,
    `created_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_login`      TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel rumah
CREATE TABLE IF NOT EXISTS `houses` (
    `id`        INT(11) NOT NULL AUTO_INCREMENT,
    `x`         FLOAT NOT NULL,
    `y`         FLOAT NOT NULL,
    `z`         FLOAT NOT NULL,
    `interior`  INT(11) NOT NULL DEFAULT 0,
    `price`     INT(11) NOT NULL DEFAULT 0,
    `owner`     VARCHAR(24) NOT NULL DEFAULT '',
    `locked`    TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel bisnis
CREATE TABLE IF NOT EXISTS `businesses` (
    `id`        INT(11) NOT NULL AUTO_INCREMENT,
    `x`         FLOAT NOT NULL,
    `y`         FLOAT NOT NULL,
    `z`         FLOAT NOT NULL,
    `interior`  INT(11) NOT NULL DEFAULT 0,
    `price`     INT(11) NOT NULL DEFAULT 0,
    `owner`     VARCHAR(24) NOT NULL DEFAULT '',
    `type`      TINYINT(1) NOT NULL DEFAULT 0,
    `locked`    TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel SPBU
CREATE TABLE IF NOT EXISTS `fuel_stations` (
    `id`        INT(11) NOT NULL AUTO_INCREMENT,
    `x`         FLOAT NOT NULL,
    `y`         FLOAT NOT NULL,
    `z`         FLOAT NOT NULL,
    `pertalite` INT(11) NOT NULL DEFAULT 1000,
    `pertamax`  INT(11) NOT NULL DEFAULT 1000,
    `solar`     INT(11) NOT NULL DEFAULT 1000,
    `dexlite`   INT(11) NOT NULL DEFAULT 500,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel kendaraan pemain
CREATE TABLE IF NOT EXISTS `player_vehicles` (
    `id`        INT(11) NOT NULL AUTO_INCREMENT,
    `owner`     VARCHAR(24) NOT NULL,
    `model`     INT(11) NOT NULL,
    `x`         FLOAT NOT NULL DEFAULT 0,
    `y`         FLOAT NOT NULL DEFAULT 0,
    `z`         FLOAT NOT NULL DEFAULT 0,
    `a`         FLOAT NOT NULL DEFAULT 0,
    `color1`    INT(11) NOT NULL DEFAULT 0,
    `color2`    INT(11) NOT NULL DEFAULT 0,
    `fuel`      FLOAT NOT NULL DEFAULT 50.0,
    `fuel_type` TINYINT(1) NOT NULL DEFAULT 0,
    `locked`    TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel kontak telepon
CREATE TABLE IF NOT EXISTS `phone_contacts` (
    `id`        INT(11) NOT NULL AUTO_INCREMENT,
    `owner`     VARCHAR(24) NOT NULL,
    `name`      VARCHAR(24) NOT NULL,
    `number`    INT(11) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel SMS
CREATE TABLE IF NOT EXISTS `phone_messages` (
    `id`        INT(11) NOT NULL AUTO_INCREMENT,
    `from_num`  INT(11) NOT NULL,
    `to_num`    INT(11) NOT NULL,
    `message`   VARCHAR(128) NOT NULL,
    `time`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `read`      TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel pemerintahan
CREATE TABLE IF NOT EXISTS `government` (
    `id`          INT(11) NOT NULL AUTO_INCREMENT,
    `player_id`   INT(11) NOT NULL,
    `player_name` VARCHAR(24) NOT NULL,
    `type`        TINYINT(1) NOT NULL COMMENT '1=Gubernur, 2=Walikota',
    `tax_rate`    INT(11) NOT NULL DEFAULT 10,
    `pns_salary`  INT(11) NOT NULL DEFAULT 15000,
    `start_time`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `active`      TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel sidang
CREATE TABLE IF NOT EXISTS `court_cases` (
    `id`          INT(11) NOT NULL AUTO_INCREMENT,
    `suspect`     VARCHAR(24) NOT NULL,
    `judge`       VARCHAR(24) NOT NULL,
    `article`     VARCHAR(64) NOT NULL,
    `fine`        INT(11) NOT NULL DEFAULT 0,
    `jail_time`   INT(11) NOT NULL DEFAULT 0,
    `verdict`     TINYINT(1) NOT NULL DEFAULT 0,
    `time`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel resep dokter
CREATE TABLE IF NOT EXISTS `prescriptions` (
    `id`          INT(11) NOT NULL AUTO_INCREMENT,
    `patient`     VARCHAR(24) NOT NULL,
    `doctor`      VARCHAR(24) NOT NULL,
    `medicine`    VARCHAR(64) NOT NULL,
    `cost`        INT(11) NOT NULL DEFAULT 0,
    `time`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabel log pajak
CREATE TABLE IF NOT EXISTS `tax_log` (
    `id`          INT(11) NOT NULL AUTO_INCREMENT,
    `player_name` VARCHAR(24) NOT NULL,
    `tax_type`    VARCHAR(32) NOT NULL,
    `amount`      INT(11) NOT NULL DEFAULT 0,
    `time`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
