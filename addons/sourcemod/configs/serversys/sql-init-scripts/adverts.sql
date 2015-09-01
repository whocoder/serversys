SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";

CREATE TABLE IF NOT EXISTS `adverts` (
  `advertid` int(11) NOT NULL,
  `sid` int(11) NOT NULL,
  `text` varchar(128) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

ALTER TABLE `adverts`
  ADD PRIMARY KEY (`advertid`);

ALTER TABLE `adverts`
  MODIFY `advertid` int(11) NOT NULL AUTO_INCREMENT;
