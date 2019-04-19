<%
dim UC,UCCLASS,SAVE,RETURN_TYPE
set UC = new UC_Class
Class UC_Class
	
	public lang,errMsg,errorLink,actionLink,isValidPowered,runMsg,runMsgCount,runAuxJSON
	public footerEchoCount,headerEchoCount,breadcrumbEchoCount,runDisplayIsEcho,title
	public actionFinishSuccess,actionFinishSuccessText,actionFinishFailText
	private aArr,oRs,sSQL,iI,iJ,sHtml,sString
	
	private sub class_initialize()
		call console.log("<span class=""text"">UC.class_initialize:start</span>")
		runDisplayIsEcho = true
		footerEchoCount  = 0
		headerEchoCount  = 0
		runMsgCount      = 0
		set lang   = server.createObject(OW.dictName)
		set errMsg = server.createObject(OW.dictName)
		set runMsg = server.createObject(OW.dictName)
		call console.log("<span class=""text"">UC.class_initialize:end</span>")
	end sub
	
	private sub class_terminate()
		set lang = nothing
	end sub
	
	public sub init()
				SAVE        = CBool(OW.regReplace(OW.getForm("get","save"),"[^a-z]","")="true")
				RETURN_TYPE = OW.regReplace(OW.getForm("get","return_type"),"[^a-z]","")
				call OS.includeLanguageFile("uc.lang.asp")
				isValidPowered = OS.isValidPowered
		if OW.isNul(CTL) then
			CTL = "index"
			ACT = "view"
		end if
		UC.title = UC.lang(100)
	end sub
	
	public function actionFinishRun()
		dim s,json,links
		runMsgCount = runMsgCount + 1
		if RETURN_TYPE="json" then
			if actionFinishSuccess then
				s    = "{""message"":"""& OW.escape(actionFinishSuccessText(0)) &"""}"
				json = "{""result"":""success"",""messages"":["& s &"]"& OW.iif(runAuxJSON<>"",","& runAuxJSON,"") &"}"
			else
				s    = "{""message"":"""& OW.escape(actionFinishFailText(0)) &"""}"
				json = "{""result"":""failed"",""messages"":["& s &"]"& OW.iif(runAuxJSON<>"",","& runAuxJSON,"") &"}"
			end if
			runMsg(runMsgCount) = json
		else
			if actionFinishSuccess then
				s = s &"<div class=""display-site-name""><a href="""& SITE_URL &""">"& SITE_NAME &"</a></div><div class=""action-display success"" result=""success"" name=""display""><h3>"& OS.lang(239) &"</h3><div class=""action-message"">"& actionFinishSuccessText(0) &"</div><div class=""buttons"" name=""buttons"">"& UC.actionLinks(actionFinishSuccessText(1)) &"</div></div>"
				s = s &"<script type=""text/javascript"">$(document).ready(function(){UC.runDisplay();});</script>"
			else
				s = s &"<div class=""display-site-name""><a href="""& SITE_URL &""">"& SITE_NAME &"</a></div><div class=""action-display failed"" result=""failed"" name=""display""><h3>"& OS.lang(239) &"</h3><div class=""action-message"">"& actionFinishFailText(0) &"</div><div class=""buttons"" name=""buttons"">"& UC.actionLinks(actionFinishFailText(1)) &"</div></div>"
				s = s &"<script type=""text/javascript"">$(document).ready(function(){UC.runDisplay();});</script>"
			end if
			runMsg(runMsgCount) = s
		end if
	end function
	
	public function actionLinks(byval links)
		dim i,arr,s
		if isArray(links) then
			for i=0 to ubound(links)
				arr = split(links(i),">")
				s = s & "<a class=""btn"& OW.iif(i=0," btn-primary","") &""" href="""& arr(1) &""">"& arr(0) &"</a>"
			next
		else
			if links<>"" then
				if instr(links,">")>0 then
					arr = split(links,">")
					s = "<a class=""btn btn-primary"" href="""& arr(1) &""">"& arr(0) &"</a>"
				else
					s = "<a class=""btn btn-primary"" href="""& links &""">"& OS.lang(223) &"</a>"
				end if 
			else
				s = "<a class=""btn btn-primary"" href=""javascript:OW.goBack();"">"& OS.lang(224) &"</a>"
			end if
		end if
		actionLinks = s
	end function
	
	public function run()
		dim f
		if LOGINED then
			if OW.isMobile then
				if CTL="setting" or CTL="password" then
					call Client.isNeedRedirectToBindMobilePage()
				end if
			else
				if CTL="setting" or CTL="password" then
					call Client.isNeedRedirectToBindMobilePage()
				end if
			end if
		end if
		if OW.isMobile then
			f = "ow-ucenter/mobile/"& CTL &".class.asp"
		else
			f = "ow-ucenter/pc/"& CTL &".class.asp"
		end if
		UCCLASS    = "UC_"& ucase(CTL)
		if UC.valid() then
			call OW.include(f)
			execute("set "& UCCLASS &" = new "& UCCLASS &"_CLASS")
			execute(""& UCCLASS &".init()")
		end if
		call runDisplay()
	end function
	
		public function runDisplay()
		dim i,s,json
		if OW.isArray(errMsg) then
			if RETURN_TYPE="json" then
				for i=0 to ubound(errMsg)
					if i=ubound(errMsg) then
						s = s &"{""message"":"""& OW.escape(errMsg(i)) &"""}"
					else
						s = s &"{""message"":"""& OW.escape(errMsg(i)) &"""},"
					end if
				next
				json = "{""result"":""error"",""messages"":["& s &"]}"
				echo json
			else
				for i=0 to ubound(errMsg)
					s = s &"<li>"& errMsg(i) &"</li>"
				next
				s = "<div class=""display-site-name""><a href="""& SITE_URL &""">"& SITE_NAME &"</a></div><div class=""error-display"" name=""display""><h3>"& OS.lang(220) &"</h3><ul>"& s &"</ul>"&"<div class=""buttons"" name=""buttons"">"& UC.actionLinks(errorLink) &"</div></div>"
				s = s &"<script type=""text/javascript"">$(document).ready(function(){//UC.runDisplay();});</script>"
				call echoHeader()
				echo s
				call echoFooter()
			end if
		else
			if runDisplayIsEcho then
				if RETURN_TYPE<>"json" then call UC.echoHeader() : end if
				for i=1 to runMsgCount
					s = s & runMsg(i)
				next
				echo s
				if RETURN_TYPE<>"json" then call UC.echoFooter() : end if
			end if
		end if
	end function
	
				public function errorSetting(byval msg)
		dim k
		if OW.isArray(errMsg) then
			k = ubound(errMsg) + 1
			redim preserve errMsg(k) : errMsg(k) = msg
		else
			redim errMsg(0) : errMsg(0) = msg
		end if
	end function
	
	public function errorHtml(byval s)
		errorHtml = "<div class=""ow-error-section"">"& s &"</div>"
	end function
	
	public function echoFooter()
		if footerEchoCount<1 then
			footerEchoCount = 1
			echo UC.footer()
		end if
	end function
	
	public function echoHeader()
		if headerEchoCount<1 then
			headerEchoCount = 1
			echo UC.header()
		end if
	end function
	
	public function footer()
		sHtml = "</body>"&vbCrLf
		sHtml = sHtml &"</html>"&vbCrLf
		footer = sHtml
	end function
	
	public function header()
		sHtml = "<!DOCTYPE HTML>"&vbCrLf
		sHtml = sHtml &"<html>"&vbCrLf
		sHtml = sHtml &"<head>"&vbCrLf
		if OW.isMobile then
			sHtml = sHtml &"<meta charset=""UTF-8"">"
		else
			sHtml = sHtml &"<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"">"&vbCrLf
		end if
		sHtml = sHtml &"<title>"& UC.title &" - "& SITE_NAME &"</title>"&vbCrLf
		sHtml = sHtml &"<meta name=""keywords"" content="""& UC.lang(100) &""" />"&vbCrLf
		sHtml = sHtml &"<meta name=""description"" content="""& UC.lang(100) &""" />"&vbCrLf
		if OW.isMobile then
			sHtml = sHtml &"<meta name=""viewport"" content=""width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no""/>"&vbCrLf
			sHtml = sHtml &"<meta name=""format-detection"" content=""telephone=no, email=no"">"&vbCrLf
			sHtml = sHtml &"<meta name=""apple-mobile-web-app-title"" content="""& SITE_NAME &""" />"&vbCrLf
		end if
		sHtml = sHtml &"<meta name=""generator"" content=""OpenWBS "& OW_VERSION &""" />"&vbCrLf
		sHtml = sHtml &"<meta name=""author"" content=""OpenWBS Team"" />"&vbCrLf
		sHtml = sHtml &"<meta name=""copyright"" content=""2008-2020 OpenWBS Inc."" />"&vbCrLf
		sHtml = sHtml &"<link rel=""shortcut icon"" href="""& OW.config("site_favicon") &"""/>"&vbCrLf
		if OW.isMobile then
			sHtml = sHtml &"<link rel=""stylesheet"" href=""css/mobile.css?v="& OW_VERSION_SN &""" />"&vbCrLf
			sHtml = sHtml &"<link rel=""stylesheet"" href=""css/mobile.ucenter.css?v="& OW_VERSION_SN &""" />"&vbCrLf
			sHtml = sHtml &"<script type=""text/javascript"" src=""../ow-content/js/mobile/jquery.js?v="& OW_VERSION_SN &"""></script>"&vbCrLf
			sHtml = sHtml &"<script type=""text/javascript"" src=""../ow-content/js/mobile/ow.js?v="& OW_VERSION_SN &"""></script>"&vbCrLf
			sHtml = sHtml &"<script type=""text/javascript"" src=""../ow-content/js/mobile/com.js?v="& OW_VERSION_SN &"""></script>"&vbCrLf
			sHtml = sHtml &"<script type=""text/javascript"" src=""js/mobile.ucenter.js?v="& OW_VERSION_SN &"""></script>"&vbCrLf
		else
			sHtml = sHtml &"<link rel=""stylesheet"" href=""css/pc.ucenter.css?v="& OW_VERSION_SN &""" />"&vbCrLf
			sHtml = sHtml &"<script type=""text/javascript"" src=""../ow-content/js/pc/jquery.js?v="& OW_VERSION_SN &"""></script>"&vbCrLf
			sHtml = sHtml &"<script type=""text/javascript"" src=""../ow-content/js/pc/ow.js?v="& OW_VERSION_SN &"""></script>"&vbCrLf
			sHtml = sHtml &"<script type=""text/javascript"" src=""js/pc.ucenter.js?v="& OW_VERSION_SN &"""></script>"&vbCrLf
		end if
		sHtml = sHtml &"<script type=""text/javascript"">"&vbCrLf
		sHtml = sHtml &"OW.debug    = """& lcase(DEBUG) &"""==""true"" ? true : false;"&vbCrLf
		sHtml = sHtml &"OW.logined  = """& lcase(LOGINED) &"""==""true"" ? true : false;"&vbCrLf
		sHtml = sHtml &"OW.sitePath = """& SITE_PATH &""";"&vbCrLf
		sHtml = sHtml &"OW.siteUrl  = """& SITE_URL &""";"&vbCrLf
		sHtml = sHtml &"OW.siteHurl = """& SITE_HURL &""";"&vbCrLf
		sHtml = sHtml &"OW.siteHtmlFileSuffix  = """& SITE_HTML_FILE_SUFFIX &""";"&vbCrLf
		sHtml = sHtml &"OW.ucenterHurl = """& UCENTER_HURL &""";"&vbCrLf
		sHtml = sHtml &"OW.cookie.cookiePre    = """& COOKIE_PRE &""";"&vbCrLf
		sHtml = sHtml &"OW.cookie.cookieDomain = """& COOKIE_DOMAIN &""";"&vbCrLf
		sHtml = sHtml &"OW.cookie.cookiePath   = """& COOKIE_PATH &""";"&vbCrLf
		sHtml = sHtml &"UC.ctl = """& CTL &""";"&vbCrLf
		sHtml = sHtml &"UC.act = """& ACT &""";"&vbCrLf
		sHtml = sHtml &"</script>"&vbCrLf
		sHtml = sHtml &"</head>"&vbCrLf
		sHtml = sHtml &"<body>"&vbCrLf
		header = sHtml
	end function
	
	public function htmlHeader()
		dim sb,str : set sb = OW.stringBuilder()
		sb.append "<div id=""header"">"
		sb.append "<div class=""toper"">"
		sb.append "<div class=""wrapper"">"
		sb.append "<div id=""top-account"" class=""top-account"">"
		sb.append "<div id=""top-account-item"" class=""top-account-item""><a href="""& UCENTER_URL &""">"& USERNAME &"<i></i></a></div>"
		sb.append "<div id=""top-account-sub"" class=""top-account-sub""><ul>"
		sb.append "<li class=""edit-setting""><a href="""& UCENTER_HURL &"ctl=setting""><i></i>"& UC.lang(101) &"</a></li>"
		sb.append "<li class=""edit-password""><a href="""& UCENTER_HURL &"ctl=password""><i></i>"& UC.lang(102) &"</a></li>"
		sb.append "<li class=""logout""><a href="""& OW.urlRewrite("l2") &"""><i></i>"& UC.lang(103) &"</a></li>"
		sb.append "</ul></div></div>"
		sb.append "<div class=""logo""><a href="""& SITE_URL &""" title="""& SITE_NAME &""">"& OW.iif(OW.config("site_ucenter_logo")="","<span>"& SITE_NAME &"</span>","<img src="""& OW.config("site_ucenter_logo") &""" />") &"</a></div>"
		sb.append htmlUCNav(0)
		sb.append "</div>"
		sb.append "</div>"
		sb.append "</div>"
		str = sb.toString() : set sb = nothing
		htmlHeader = str
	end function
	
	public function htmlHeaderMobile(byval l,byval t)
		dim s
		s = s &"<header class=""om-header"">"& l &"<div class=""title"">"& t &"</div>"
        s = s &"<a class=""menu"" id=""top_menu"" href=""javascript:;""></a>"
        s = s &"<div class=""menu-section"" id=""top_menu_section"" style=""display:none;"">"
		s = s &"<div class=""close""><a href=""javascript:;"" id=""top_menu_close""></a></div>"
		s = s & htmlUCNav(1)
        s = s &"</div>"
		s = s &"</header>"
		s = s &"<script type=""text/javascript"">$(document).ready(function(){UC.menu();});</script>"
		htmlHeaderMobile = s
	end function
	
	public function htmlFooter()
		dim s
		if OW.isMobile then
			s = htmlFooterMobile()
		else
			s = htmlFooterPC()
		end if
		htmlFooter = s
	end function
	
	public function htmlFooterMobile()
		dim i,navIcon,navLink,navName,target,rs,sb,str : set sb = OW.stringBuilder()
		sb.append "<footer class=""om-footer"">"
		sb.append OS.ucenterFooter("mobile")
		sb.append "</footer>"
		sb.append "<nav class=""ow-nav"" id=""ow_nav"">"
		sb.append "<section>"
		sb.append "<ul class=""base"" id=""ow_nav_base"">"
		i = 0
		set rs = OW.DB.getRecordBySQL("SELECT * FROM "& DB_PRE &"navigator WHERE type=5 AND status=0 AND parent_id=0 AND not(forbid_group_id like '%,"& GROUP_ID &",%' OR forbid_group_id like '%,"& SPECIAL_GROUP_ID &",%') AND "& OW.DB.auxSQL &" ORDER BY sequence ASC")
		do while not rs.eof
			i = i + 1
			navIcon = rs("icon")
			navLink = rs("url")
			navLink = replace(navLink,"{$site_url}",SITE_URL)
			navLink = replace(navLink,"{$site_hurl}",SITE_HURL)
			navName = rs("name")
			target  = OW.rs(rs("target"))
			sb.append "<li class=""n1"" n1=""true"" i="""& i &""" url="""& navLink &""">"
			sb.append "<a class=""n1"" href="""& navLink &""" style=""background-image:url("& navIcon &");"" "& OW.iif(target="_blank","target=""_blank""","") &">"& navName &"</a>"
			if OW.int(rs("children"))>0 then
				sb.append "<span class=""caret""></span>"
				sb.append "<div class=""subnav"" name=""subnav"" i="""& i &""">"& subNav(rs("nav_id")) &"</div>"
			end if
			sb.append "</li>"
			rs.movenext
		loop
		OW.DB.closeRs rs
		sb.append "</ul>"
		sb.append "</section>"
		sb.append "</nav>"
		sb.append "<script type=""text/javascript"">"
		sb.append "$(document).ready(function(){"
		sb.append "OW.mobile.nav({omNav:$(""#ow_nav""),baseNav:$(""#ow_nav_base"")});"
		sb.append "});"
        sb.append "</script>"
		str = sb.toString() : set sb = nothing
		htmlFooterMobile = str
	end function
	
	public function subNav(byval navid)
		dim i,rs,navLink,navName,target
		dim sb,str : set sb = OW.stringBuilder()
		sb.append "<ul>"
		set rs = OW.DB.getRecordBySQL("SELECT * FROM "& DB_PRE &"navigator WHERE type=5 AND status=0 AND parent_id="& navid &" AND not(forbid_group_id like '%,"& GROUP_ID &",%' OR forbid_group_id like '%,"& SPECIAL_GROUP_ID &",%') AND "& OW.DB.auxSQL &" ORDER BY sequence ASC")
		do while not rs.eof
			i = i + 1
			navLink = rs("url")
			navLink = replace(replace(navLink,"{$site_url}",SITE_URL),"{$site_hurl}",SITE_HURL)
			navName = rs("name")
			target  = OW.rs(rs("target"))
			sb.append "<li class=""n2""><a class=""n2"" href="""& navLink &""" "& OW.iif(target="_blank","target=""_blank""","") &">"& navName &"</a></li>"
			rs.movenext
		loop
		OW.DB.closeRs rs
		sb.append "</ul>"
		str = sb.toString() : set sb = nothing
		subNav = str
	end function
	
	public function htmlFooterPC()
		dim sb,str : set sb = OW.stringBuilder()
		sb.append "<div id=""footer"">"
		sb.append "<div class=""wrapper"">"
		sb.append OS.ucenterFooter("pc")
		sb.append "</div>"
		sb.append "</div>"
		sb.append "<script type=""text/javascript"">"
		sb.append "$(document).ready(function(){UC.init();});"
		sb.append "</script>"
		str = sb.toString() : set sb = nothing
		htmlFooterPC = str
	end function
	
	public function htmlUCNav(byval isMobile)
		dim rs,s,url,target
		set rs = OW.DB.getRecordBySQL("SELECT * FROM "& DB_PRE &"navigator WHERE type=4 AND status=0 AND parent_id=0 AND not(forbid_group_id like '%,"& GROUP_ID &",%' OR forbid_group_id like '%,"& SPECIAL_GROUP_ID &",%') AND "& OW.DB.auxSQL &" ORDER BY sequence ASC")
		do while not rs.eof
			url    = OW.rs(rs("url"))
			url    = OW.reps(url,"{$site_url}",SITE_URL)
			url    = OW.reps(url,"{$site_hurl}",SITE_HURL)
			target = OW.rs(rs("target"))
			s = s &"<li><a href="""& url &""" "& OW.iif(target="_blank" and isMobile=0,"target=""_blank""","") &">"& OW.rs(rs("name")) &"</a></li>"
			rs.movenext
		loop
		OW.DB.closeRs rs
		if not(OW.isNul(s)) then
			s = "<ul class=""top-nav"" name=""top-nav"">"& s &"</ul>"
		end if
		htmlUCNav = s
	end function
	
	public function htmlSider()
		dim rs
		dim sb,str : set sb = OW.stringBuilder()
		sb.append "<div id=""sidebar"">"
		sb.append "<div class=""heading""></div>"
		sb.append "<div class=""uc-sidenav"">"
		sb.append "<ul>"
		sb.append "<li class=""index"" name=""index""><a href="""& UCENTER_HURL &"ctl=index""><i></i>"& UC.lang(1) &"</a></li>"
		sb.append "</ul>"
				sb.append APIOS.ucenterPCAuxMenu()
				sb.append "<ul>"
		if OS.versionType="x" then
			sb.append "<li class=""orders"" name=""orders""><a href="""& UCENTER_HURL &"ctl=orders""><i></i>"& UC.lang(6) &"</a></li>"
			sb.append "<li class=""finance"" name=""finance""><a href="""& UCENTER_HURL &"ctl=finance""><i></i>"& UC.lang(2) &"</a></li>"
		end if
		sb.append "<li class=""point"" name=""point""><a href="""& UCENTER_HURL &"ctl=point""><i></i>"& UC.lang(3) &"</a></li>"
		if OS.versionType="x" then
			if OW.config("is_fenxiao_open")=1 then
				sb.append "<li class=""fenxiao"" name=""fenxiao""><a href="""& UCENTER_HURL &"ctl=fenxiao""><i></i>"& UC.lang(10) &"</a></li>"
			end if
			sb.append "<li class=""coupon"" name=""coupon""><a href="""& UCENTER_HURL &"ctl=coupon""><i></i>"& UC.lang(7) &"</a></li>"
			sb.append "<li class=""favorite"" name=""favorite""><a href="""& UCENTER_HURL &"ctl=favorite""><i></i>"& UC.lang(8) &"</a></li>"
		end if
		sb.append "<li class=""setting"" name=""setting""><a href="""& UCENTER_HURL &"ctl=setting""><i></i>"& UC.lang(4) &"</a></li>"
		if OS.versionType="x" then
			sb.append "<li class=""order-form-data"" name=""order_form_data""><a href="""& UCENTER_HURL &"ctl=order_form_data""><i></i>"& UC.lang(9) &"</a></li>"
		end if
		sb.append "<li class=""system-msg"" name=""system_msg""><a href="""& UCENTER_HURL &"ctl=system_msg""><i></i>"& UC.lang(5) &"</a></li>"
		sb.append "</ul>"
				sb.append "<ul>"
		set rs = OW.DB.getRecordBySQL("SELECT form_id,name,[table] FROM "& DB_PRE &"form WHERE is_ucenter_show=1 AND status=0 AND "& OW.DB.auxSQL &" ORDER BY sequence ASC")
		do while not rs.eof
			sb.append "<li class=""form form-"& rs("table") &""" name=""form-"& rs("form_id") &"""><a href="""& UCENTER_HURL &"ctl=form&act=list&form_id="& rs("form_id") &"""""><i class=""glyphicon glyphicon-edit""></i>"& rs("name") &"</a></li>"
			rs.movenext
		loop
		OW.DB.closeRs rs
		sb.append "</ul>"
				sb.append "</div>"
		sb.append "</div>"
		str = sb.toString() : set sb = nothing
		htmlSider = str
	end function
	
		public function valid()
		dim check : check = true
				if SAVE and not OW.validClientPost() then
			check = false
			call UC.errorSetting(OS.lang(232))
		end if
				if not LOGINED then
			check = false
			UC.errorLink = array(OS.lang(222) &">"& OW.urlRewrite("l1") &"",""& OS.lang(224) &">"& OW.urlRewrite("l1") &"")
			UC.errorSetting(OS.lang(244))
		end if
		valid = check
	end function
end Class
%>