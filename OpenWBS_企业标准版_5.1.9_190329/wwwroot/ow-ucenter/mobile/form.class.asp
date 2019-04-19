<%
dim UC_FORM
class UC_FORM_CLASS
	
	private oRs,sSQL,sString
	private formId,formExist,formTable
	
	private sub class_initialize()
	end sub
	
	public sub init()
		formId = OW.int(OW.getForm("get","form_id"))
		select case ACT
		case "add"
			call getFormInfo()
			if formExist then
				call addHtml()
			else
				UC.errorLink = array("用户中心>"& UCENTER_URL &"",OS.lang(75) &">javascript:OW.goBack();")
				call UC.errorSetting("表单不存在")
			end if
		case "delete"
			call delete()
		case else
			call getFormInfo()
			if formExist then
				call main()
			else
				UC.errorLink = array("用户中心>"& UCENTER_URL &"",OS.lang(75) &">javascript:OW.goBack();")
				call UC.errorSetting("表单不存在")
			end if
		end select
	end sub
	
	private sub class_terminate()
	end sub
	
	public function getFormInfo()
		dim i,fieldsCount
		set oRs = OW.DB.getRecordBySQL("SELECT * FROM "& DB_PRE &"form WHERE form_id="& formId &" AND is_ucenter_show=1 AND "& OW.DB.auxSQL &"")
		fieldsCount = oRs.fields.count-1
		if oRs.eof then
			formExist = false
		else
			formExist = true
			for i=1 to fieldsCount
				V(oRs.fields(i).name) = OW.rs(oRs(oRs.fields(i).name))
			next
		end if
		OW.DB.closeRs oRs
		formTable = OW.DB.Table.formPre & V("table")
	end function
	
	private function addHtml()
		call UC.echoHeader()
%>
    <%=UC.htmlHeaderMobile("<a href="""& UCENTER_URL &""" class=""ucenter""></a>",V("name"))%>
    <section id="mbody">
        <div class="ow-formdata" id="formdata">
            <% if V("description")<>"" then %>
            <div class="ow-form-desc"><%=OW.editorContentClientDecode(V("description"))%></div>
            <% end if %>
            <div class="section" id="list">
                <%=Client.formPostHtml(formId)%>
            </div>
        </div>
    </section>
    
	<%=UC.htmlFooter()%>
<%
		call UC.echoFooter()
	end function
	
	private function main()
		call UC.echoHeader()
%>
    <%=UC.htmlHeaderMobile("<a href="""& UCENTER_URL &""" class=""ucenter""></a>",V("name"))%>
    <section id="mbody">
        <div class="ow-formdata" id="formdata">
            <div class="header">
                <a class="btn btn-primary" href="<%=UCENTER_HURL%>ctl=<%=CTL%>&act=add&form_id=<%=formId%>"><i class="glyphicon glyphicon-plus"></i><%=V("name")%></a>
            </div>
            <div class="section" id="list">
                <%=formDataList()%>
            </div>
        </div>
    </section>
    
	<%=UC.htmlFooter()%>
<%
		call UC.echoFooter()
	end function
	
	public function formDataList()
		dim aArr,arr,i,rs,fields
		dim dataId,formData,name,value,formReply
		dim sb,str : set sb = OW.stringBuilder()
		'**
		arr    = OW.DB.getFieldValueBySQL("SELECT [field_name] FROM "& DB_PRE &"form_field WHERE form_id="& formId &" AND display_in_client=1 AND "& OW.DB.auxSQL &"ORDER BY sequence")
		aArr   = OW.DB.getFieldValueBySQL("SELECT [field] FROM "& DB_PRE &"form_field WHERE form_id="& formId &" AND display_in_client=1 AND "& OW.DB.auxSQL &" ORDER BY sequence")
		if not(OW.isArray(aArr)) then
			arr  = split(arr,",")
		end if
		if not(OW.isArray(aArr)) then
			aArr = split(aArr,",")
		end if
		fields = OW.join(aArr,"],[")
		if OW.isNotNul(fields) then fields = ",["& fields &"]" : end if
		'****
		set rs = OW.DB.getRecordBySQL("SELECT id"& fields &",uid,post_time,status FROM "& formTable &" WHERE uid="& UID &" ORDER BY id DESC")
		fieldsCount = rs.fields.count-1
		do while not rs.eof
			dataId = rs("id")
			sb.append "<div class=""ow-formdata-list"">"
			sb.append "<div class=""owui-cells"">"
			for i=0 to ubound(aArr)
				if OW.isNotNul(aArr(i)) then
					sb.append "<div class=""owui-cell""><div class=""owui-cell-hd""><label class=""owui-label"">"& arr(i) &"</label></div><div class=""owui-cell-bd"">"& OW.rs(rs(aArr(i))) &"</div></div>"
				end if
			next
			rs.movenext
			formReply = OW.rs(OW.DB.getFieldValueBySQL("SELECT content FROM "& DB_PRE &"form_reply WHERE form_id="& formId &" AND data_id="& dataId &" AND "& OW.DB.auxSQL &""))
			if formReply<>"" then
				sb.append "<div class=""owui-cell owui-cell-reply""><div class=""owui-cell-hd""><label class=""owui-label"">管理员回复</label></div><div class=""owui-cell-bd"">"& formReply &"</div></div>"
			end if
			sb.append "</div>"
			sb.append "</div>"
		loop
		OW.DB.closeRs rs
		'****
		str = sb.toString() : set sb = nothing
		formDataList = str
	end function

end class
%>

