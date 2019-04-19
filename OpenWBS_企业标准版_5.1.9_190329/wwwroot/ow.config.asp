﻿<%@LANGUAGE="VBSCRIPT.encode" CODEPAGE="65001"%>
<%
option explicit
response.charset = "utf-8"
response.buffer = true
session.codePage = 65001
server.scriptTimeOut = 300
'****
'**配置主文件
'**filename: config.main.asp
'**author: Lin XiaoDong (DX.Lin)
'**copyright: OpenWBS
'****
dim SYS_IS_INSTALL,SYS_TIME,SYS_TIME_START,SYS_CHARSET,IS_MULTI_SITES,DEVELOPER_MODE,DEBUG,DEBUG_TIME,DEBUG_SQL_SHOW,CONFIG_CACHE_OPEN,IS_BOOK_OPEN,LANGUAGES,XML_VERSION,ENCRYPT_KEY,COOKIE_PRE,COOKIE_DOMAIN,COOKIE_PATH,SESSION_PRE,CACHE_FLAG
dim DB_TYPE,DB_ACCESS_PATH,DB_SERVER,DB_PORT,DB_NAME,DB_USERNAME,DB_PASSWORD,DB_PRE
dim SITE_ID,SITE_NAME,SITE_MINI_NAME,SITE_URL,SITE_DOMAIN,SITE_PATH,SITE_HURL,SITE_FOLDER,SITE_HTML_FILE_SUFFIX,UCENTER_URL,UCENTER_HURL
SYS_IS_INSTALL = 0
SYS_TIME = now()
SYS_TIME_START = timer()
SYS_CHARSET = "utf-8"
IS_MULTI_SITES = false
DEVELOPER_MODE = false
DEBUG = false
DEBUG_TIME = false
DEBUG_SQL_SHOW = false
CONFIG_CACHE_OPEN = false
IS_BOOK_OPEN = true
LANGUAGES = array("zh-cn:简体中文")
XML_VERSION = ".3.0"
ENCRYPT_KEY = "ow"
COOKIE_PRE = "ow_"
COOKIE_DOMAIN = ""
COOKIE_PATH = "/"
SESSION_PRE = "ow_"
CACHE_FLAG = "ow_"

'**数据库配置
DB_TYPE = 0
DB_ACCESS_PATH = ""
DB_SERVER = "(local)"
DB_PORT = ""
DB_NAME = ""
DB_USERNAME = ""
DB_PASSWORD = ""
DB_PRE = "ow_"

'**网站信息
SITE_ID = 1
SITE_URL = "http://www.openwbs.com/"
SITE_DOMAIN = "www.openwbs.com" 
SITE_PATH = "/"
SITE_FOLDER = ""
SITE_HTML_FILE_SUFFIX = ".html"
%>