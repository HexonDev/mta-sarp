-- phpMyAdmin SQL Dump
-- version 4.5.4.1deb2ubuntu2.1
-- http://www.phpmyadmin.net
--
-- Gép: localhost
-- Létrehozás ideje: 2019. Már 25. 14:38
-- Kiszolgáló verziója: 5.7.25-0ubuntu0.16.04.2
-- PHP verzió: 7.0.33-0ubuntu0.16.04.2

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Adatbázis: `admin_mtasa`
--

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `accounts`
--

CREATE TABLE `accounts` (
  `accountID` int(11) NOT NULL,
  `serial` varchar(512) DEFAULT '0',
  `suspended` varchar(1) DEFAULT 'N',
  `username` varchar(48) NOT NULL DEFAULT '',
  `password` text,
  `email` text,
  `adminLevel` int(2) NOT NULL DEFAULT '0',
  `adminNick` varchar(48) NOT NULL DEFAULT '',
  `adminDutyTime` bigint(20) NOT NULL DEFAULT '0',
  `registerTime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `lastLoggedIn` datetime DEFAULT NULL,
  `maxCharacter` int(2) NOT NULL DEFAULT '1',
  `adminJail` varchar(512) NOT NULL DEFAULT 'N',
  `adminJailTime` int(11) NOT NULL DEFAULT '0',
  `premiumPoints` int(11) NOT NULL DEFAULT '0',
  `online` enum('N','Y') NOT NULL DEFAULT 'N',
  `helperLevel` int(1) NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `achievements`
--

CREATE TABLE `achievements` (
  `id` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `achievementid` int(11) DEFAULT NULL,
  `characterid` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `adminjails`
--

CREATE TABLE `adminjails` (
  `dbID` int(11) NOT NULL,
  `accountID` int(11) NOT NULL DEFAULT '0',
  `jailTimestamp` bigint(22) NOT NULL DEFAULT '0',
  `reason` text,
  `duration` int(11) NOT NULL DEFAULT '0',
  `adminName` varchar(100) NOT NULL DEFAULT ''
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `atm`
--

CREATE TABLE `atm` (
  `id` int(11) NOT NULL,
  `position` mediumtext COLLATE utf8_unicode_ci NOT NULL,
  `money` int(11) NOT NULL DEFAULT '300000'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `bans`
--

CREATE TABLE `bans` (
  `dbID` int(11) NOT NULL,
  `playerSerial` varchar(512) COLLATE utf8_hungarian_ci DEFAULT '0',
  `playerName` varchar(48) COLLATE utf8_hungarian_ci NOT NULL DEFAULT '',
  `playerAccountId` int(11) NOT NULL,
  `banReason` text COLLATE utf8_hungarian_ci,
  `adminName` varchar(48) COLLATE utf8_hungarian_ci NOT NULL DEFAULT '',
  `banTimestamp` bigint(22) DEFAULT '0',
  `expireTimestamp` bigint(22) DEFAULT '0',
  `isActive` enum('Y','N') COLLATE utf8_hungarian_ci NOT NULL DEFAULT 'Y'
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_hungarian_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `billiard`
--

CREATE TABLE `billiard` (
  `tableId` int(11) NOT NULL,
  `posX` float NOT NULL,
  `posY` float NOT NULL,
  `posZ` float NOT NULL,
  `rotZ` float NOT NULL,
  `interior` int(11) NOT NULL,
  `dimension` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_hungarian_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `characters`
--

CREATE TABLE `characters` (
  `charID` int(11) NOT NULL,
  `accID` int(11) NOT NULL DEFAULT '0',
  `name` varchar(40) NOT NULL DEFAULT '',
  `skin` int(3) NOT NULL DEFAULT '1',
  `age` int(2) NOT NULL DEFAULT '24',
  `position` text,
  `rotation` int(3) NOT NULL DEFAULT '0',
  `interior` int(11) NOT NULL DEFAULT '0',
  `dimension` int(11) NOT NULL DEFAULT '0',
  `health` int(3) NOT NULL DEFAULT '100',
  `armor` int(3) NOT NULL DEFAULT '100',
  `hunger` int(3) NOT NULL DEFAULT '100',
  `thirst` int(3) NOT NULL DEFAULT '100',
  `money` int(11) NOT NULL DEFAULT '0',
  `bankMoney` int(11) NOT NULL DEFAULT '0',
  `job` int(2) NOT NULL DEFAULT '0',
  `injured` int(1) NOT NULL DEFAULT '0',
  `jailed` text,
  `houseInterior` int(11) NOT NULL DEFAULT '0',
  `customInterior` int(11) DEFAULT '0',
  `actionbarItems` text,
  `lastOnline` int(11) NOT NULL DEFAULT '0',
  `playedMinutes` int(11) NOT NULL DEFAULT '0',
  `playTimeForPayday` int(11) NOT NULL DEFAULT '0',
  `vehicleLimit` int(4) NOT NULL DEFAULT '3',
  `interiorLimit` int(4) NOT NULL DEFAULT '5',
  `bulletDamages` varchar(512) DEFAULT NULL,
  `lastNameChange` datetime DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `dogs`
--

CREATE TABLE `dogs` (
  `id` int(120) NOT NULL,
  `name` varchar(120) COLLATE utf8_unicode_ci NOT NULL,
  `type` int(120) NOT NULL,
  `health` int(120) NOT NULL,
  `alive` int(120) NOT NULL,
  `owner` int(120) NOT NULL,
  `qualification` mediumtext COLLATE utf8_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `gates`
--

CREATE TABLE `gates` (
  `dbID` int(120) NOT NULL,
  `object` int(120) NOT NULL,
  `openposition` text NOT NULL,
  `closeposition` text NOT NULL,
  `movetime` int(120) NOT NULL,
  `interior` int(120) NOT NULL,
  `dimension` int(120) NOT NULL,
  `mode` enum('key','group','code') NOT NULL DEFAULT 'key',
  `groupID` int(11) NOT NULL DEFAULT '0',
  `code` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `groupMembers`
--

CREATE TABLE `groupMembers` (
  `index` int(11) NOT NULL,
  `groupID` int(11) NOT NULL,
  `characterID` int(11) NOT NULL,
  `rank` int(11) DEFAULT '1',
  `isLeader` varchar(1) DEFAULT 'N',
  `dutySkin` int(3) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `groupRanks`
--

CREATE TABLE `groupRanks` (
  `index` int(11) NOT NULL,
  `groupID` int(11) NOT NULL,
  `rankID` int(11) NOT NULL DEFAULT '1',
  `rankName` tinytext,
  `rankPayment` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `groups`
--

CREATE TABLE `groups` (
  `groupID` int(11) NOT NULL,
  `name` tinytext,
  `prefix` tinytext,
  `type` tinytext,
  `description` tinytext,
  `balance` int(11) DEFAULT '0',
  `permissions` text,
  `duty_skins` text,
  `duty_positions` text,
  `duty_armor` int(3) DEFAULT '0',
  `duty_items` text,
  `mainLeader` int(11) DEFAULT '0',
  `tuneRadio` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `interiors`
--

CREATE TABLE `interiors` (
  `interiorId` int(11) NOT NULL,
  `flag` enum('static','dynamic') COLLATE utf8_hungarian_ci NOT NULL DEFAULT 'dynamic',
  `ownerId` int(22) NOT NULL DEFAULT '0',
  `price` int(22) NOT NULL DEFAULT '0',
  `type` enum('building','house','garage','rentable','door') COLLATE utf8_hungarian_ci NOT NULL DEFAULT 'building',
  `name` varchar(255) COLLATE utf8_hungarian_ci NOT NULL,
  `gameInterior` int(22) NOT NULL DEFAULT '1',
  `entrance_position` text COLLATE utf8_hungarian_ci NOT NULL,
  `entrance_rotation` text COLLATE utf8_hungarian_ci NOT NULL,
  `entrance_interior` int(22) NOT NULL,
  `entrance_dimension` int(22) NOT NULL,
  `exit_position` text COLLATE utf8_hungarian_ci NOT NULL,
  `exit_rotation` text COLLATE utf8_hungarian_ci NOT NULL,
  `exit_interior` int(22) NOT NULL,
  `exit_dimension` int(22) NOT NULL,
  `locked` enum('Y','N') COLLATE utf8_hungarian_ci NOT NULL DEFAULT 'N',
  `dummy` enum('Y','N') COLLATE utf8_hungarian_ci NOT NULL DEFAULT 'N',
  `renewalTime` int(22) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_hungarian_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `items`
--

CREATE TABLE `items` (
  `dbID` int(22) NOT NULL,
  `itemId` int(3) NOT NULL,
  `slot` int(11) NOT NULL,
  `amount` int(10) NOT NULL DEFAULT '1',
  `data1` text,
  `data2` text,
  `data3` text,
  `ownerType` varchar(8) NOT NULL,
  `ownerId` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `jobnpc`
--

CREATE TABLE `jobnpc` (
  `id` bigint(20) NOT NULL,
  `position` mediumtext COLLATE utf8_unicode_ci,
  `skin` int(120) NOT NULL,
  `name` varchar(120) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `kicks`
--

CREATE TABLE `kicks` (
  `dbID` int(11) NOT NULL,
  `playerAccountId` int(11) NOT NULL,
  `adminName` varchar(48) COLLATE utf8_hungarian_ci NOT NULL,
  `kickReason` text COLLATE utf8_hungarian_ci,
  `date` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_hungarian_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `logs`
--

CREATE TABLE `logs` (
  `id` bigint(20) NOT NULL,
  `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `type` text COLLATE utf8_unicode_ci NOT NULL,
  `logstring` text COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `npcs`
--

CREATE TABLE `npcs` (
  `id` bigint(120) NOT NULL,
  `position` VARCHAR(255) NOT NULL,
  `skin` int(120) NOT NULL,
  `name` text COLLATE utf8_unicode_ci NOT NULL,
  `type` int(120) NOT NULL,
  `subtype` int(120) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `reports`
--

CREATE TABLE `reports` (
  `id` bigint(120) NOT NULL,
  `category` int(10) NOT NULL,
  `priority` int(10) NOT NULL,
  `message` mediumtext COLLATE utf8_unicode_ci,
  `createdby` int(10) NOT NULL,
  `acceptedby` int(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `shop_peds`
--

CREATE TABLE `shop_peds` (
  `pedId` int(11) NOT NULL,
  `posX` float NOT NULL,
  `posY` float NOT NULL,
  `posZ` float NOT NULL,
  `rotZ` float NOT NULL,
  `interior` int(11) NOT NULL,
  `dimension` int(11) NOT NULL,
  `skinId` int(3) NOT NULL,
  `balance` int(11) NOT NULL DEFAULT '0',
  `itemList` longtext COLLATE utf8_hungarian_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_hungarian_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `taxes`
--

CREATE TABLE `taxes` (
  `id` int(120) NOT NULL,
  `name` text COLLATE utf8_unicode_ci NOT NULL,
  `key` varchar(120) COLLATE utf8_unicode_ci NOT NULL,
  `value` int(120) NOT NULL,
  `created` bigint(120) NOT NULL,
  `updated` bigint(120) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `trashes`
--

CREATE TABLE `trashes` (
  `trashID` int(22) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `rotation` float NOT NULL,
  `interior` int(3) NOT NULL,
  `dimension` int(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Tábla szerkezet ehhez a táblához `vehicles`
--

CREATE TABLE `vehicles` (
  `vehicleID` int(11) NOT NULL,
  `model` int(10) NOT NULL DEFAULT '400',
  `owner` int(11) NOT NULL DEFAULT '0',
  `groupID` int(11) NOT NULL DEFAULT '0',
  `health` float NOT NULL DEFAULT '1000',
  `fuel` int(11) NOT NULL DEFAULT '100',
  `maxFuel` int(4) NOT NULL DEFAULT '100',
  `engine` tinyint(1) NOT NULL DEFAULT '0',
  `light` tinyint(1) NOT NULL DEFAULT '0',
  `handBrake` tinyint(1) NOT NULL DEFAULT '1',
  `locked` tinyint(1) NOT NULL DEFAULT '1',
  `position` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `parkedPosition` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `color` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `headLightColor` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `wheels` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `distance` int(11) NOT NULL DEFAULT '0',
  `panels` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `doors` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `tunings` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci,
  `lastOilChange` int(11) NOT NULL DEFAULT '0',
  `licensePlate` varchar(8) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `unit` varchar(120) NOT NULL,
  `impound` text,
  `sirenPanel` int(1) NOT NULL DEFAULT '0',
  `canUseFuelStations` varchar(255) NOT NULL DEFAULT 'Y',
  `paintjobId` int(3) NOT NULL DEFAULT '0',
  `theTicket` text,
  `wheelClamp` enum('N','Y') NOT NULL DEFAULT 'N'
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4;

--
-- Indexek a kiírt táblákhoz
--

--
-- A tábla indexei `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`accountID`),
  ADD KEY `suspended` (`suspended`);
ALTER TABLE `accounts` ADD FULLTEXT KEY `email` (`email`);

--
-- A tábla indexei `achievements`
--
ALTER TABLE `achievements`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `adminjails`
--
ALTER TABLE `adminjails`
  ADD PRIMARY KEY (`dbID`);

--
-- A tábla indexei `atm`
--
ALTER TABLE `atm`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `bans`
--
ALTER TABLE `bans`
  ADD PRIMARY KEY (`dbID`);

--
-- A tábla indexei `billiard`
--
ALTER TABLE `billiard`
  ADD PRIMARY KEY (`tableId`);

--
-- A tábla indexei `characters`
--
ALTER TABLE `characters`
  ADD PRIMARY KEY (`charID`);

--
-- A tábla indexei `dogs`
--
ALTER TABLE `dogs`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `gates`
--
ALTER TABLE `gates`
  ADD PRIMARY KEY (`dbID`);

--
-- A tábla indexei `groupMembers`
--
ALTER TABLE `groupMembers`
  ADD PRIMARY KEY (`index`);

--
-- A tábla indexei `groupRanks`
--
ALTER TABLE `groupRanks`
  ADD PRIMARY KEY (`index`);

--
-- A tábla indexei `groups`
--
ALTER TABLE `groups`
  ADD PRIMARY KEY (`groupID`);

--
-- A tábla indexei `interiors`
--
ALTER TABLE `interiors`
  ADD PRIMARY KEY (`interiorId`);

--
-- A tábla indexei `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`dbID`);

--
-- A tábla indexei `jobnpc`
--
ALTER TABLE `jobnpc`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `kicks`
--
ALTER TABLE `kicks`
  ADD PRIMARY KEY (`dbID`);

--
-- A tábla indexei `logs`
--
ALTER TABLE `logs`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `npcs`
--
ALTER TABLE `npcs`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `shop_peds`
--
ALTER TABLE `shop_peds`
  ADD PRIMARY KEY (`pedId`);

--
-- A tábla indexei `taxes`
--
ALTER TABLE `taxes`
  ADD PRIMARY KEY (`id`);

--
-- A tábla indexei `trashes`
--
ALTER TABLE `trashes`
  ADD PRIMARY KEY (`trashID`);

--
-- A tábla indexei `vehicles`
--
ALTER TABLE `vehicles`
  ADD PRIMARY KEY (`vehicleID`);

--
-- A kiírt táblák AUTO_INCREMENT értéke
--

--
-- AUTO_INCREMENT a táblához `accounts`
--
ALTER TABLE `accounts`
  MODIFY `accountID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `achievements`
--
ALTER TABLE `achievements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `adminjails`
--
ALTER TABLE `adminjails`
  MODIFY `dbID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `atm`
--
ALTER TABLE `atm`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `bans`
--
ALTER TABLE `bans`
  MODIFY `dbID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `billiard`
--
ALTER TABLE `billiard`
  MODIFY `tableId` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `characters`
--
ALTER TABLE `characters`
  MODIFY `charID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `dogs`
--
ALTER TABLE `dogs`
  MODIFY `id` int(120) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `gates`
--
ALTER TABLE `gates`
  MODIFY `dbID` int(120) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `groupMembers`
--
ALTER TABLE `groupMembers`
  MODIFY `index` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `groupRanks`
--
ALTER TABLE `groupRanks`
  MODIFY `index` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `groups`
--
ALTER TABLE `groups`
  MODIFY `groupID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `interiors`
--
ALTER TABLE `interiors`
  MODIFY `interiorId` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `items`
--
ALTER TABLE `items`
  MODIFY `dbID` int(22) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `jobnpc`
--
ALTER TABLE `jobnpc`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `kicks`
--
ALTER TABLE `kicks`
  MODIFY `dbID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `logs`
--
ALTER TABLE `logs`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `npcs`
--
ALTER TABLE `npcs`
  MODIFY `id` bigint(120) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `reports`
--
ALTER TABLE `reports`
  MODIFY `id` bigint(120) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `shop_peds`
--
ALTER TABLE `shop_peds`
  MODIFY `pedId` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `taxes`
--
ALTER TABLE `taxes`
  MODIFY `id` int(120) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `trashes`
--
ALTER TABLE `trashes`
  MODIFY `trashID` int(22) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT a táblához `vehicles`
--
ALTER TABLE `vehicles`
  MODIFY `vehicleID` int(11) NOT NULL AUTO_INCREMENT;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
