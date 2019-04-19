<!--#include file="../ow.config.asp"-->
<%
'系统后台主类
'2006-3-9 修正了一个可能除0的错误
'2006-7-31 字符个数随机，宽度、高度、位置随机，加入干扰线
'**

'禁止缓存
Response.Expires = -9999
Response.buffer=true
Response.ExpiresAbsolute = Now() - 1 
Response.Expires = 0 
Response.CacheControl = "no-cache"
Response.ContentType = "Image/BMP"
Response.AddHeader "Pragma","no-cache"
Response.AddHeader "cache-ctrol","no-cache"

'**设置部分
Const nSaturation = 80			' 色彩饱和度
Const nBlankNoisyDotOdds = 0.00 ' 空白处噪点率
Const nColorNoisyDotOdds = 0.00 ' 有色处噪点率
Const nNoisyLineCount = 0		' 噪音线条数
Const nCharMin = 5				' 产生的最小字符个数
Const nCharMax = 5				' 产生的最大字符个数
Const nSpaceX = 2				' 左右两边的空白宽度
Const nSpaceY = 2				' 上下两边的空白宽度
Const nImgWidth = 68			' 数据区宽度
Const nImgHeight = 20			' 数据区高度
Const nCharWidthRandom = 6		' 字符宽度随机量
Const nCharHeightRandom = 6	    ' 字符高度随机量
Const nPositionXRandom = 1		' 横向位置随机量
Const nPositionYRandom = 1		' 纵向位置随机量
Const nAngleRandom = 2         	' 笔画角度随机量
Const nLengthRandom = 2        	' 笔画长度随机量(百分比)
Const nColorHue = -2			' 显示验证码的色调(-1表示随机色调, -2表示灰度色调)
Const cCharSet = "123456789"    ' 构成验证码的字符集
                                ' 如果扩充了下边的字母矢量库，则可以相应扩充这个字符集
'**
Randomize
Dim Buf(), DigtalStr
Dim Lines(), LineCount
Dim CursorX, CursorY, DirX, DirY, nCharCount, nPixelWidth, nPixelHeight, PicWidth, PicHeight
nCharCount = nCharMin + CInt(Rnd * (nCharMax - nCharMin))
PicWidth = nImgWidth + 2 * nSpaceX
PicHeight = nImgHeight + 2 * nSpaceY

call createVerifyCode(SESSION_PRE &"vfycode"& trim(request.QueryString("key")))

sub CDGen_Reset()
	'复位矢量笔和环境变量
	LineCount = 0
	CursorX = 0
	CursorY = 0
	'初始的光笔方向是垂直向下
	DirX = 0
	DirY = 1
end sub

sub CDGen_Clear()
	' 清空位图阵列
	Dim i, j
	ReDim Buf(PicHeight - 1, PicWidth - 1)
	For j = 0 To PicHeight - 1
		For i = 0 To PicWidth - 1
			Buf(j, i) = 0
		Next
	Next
end sub

sub CDGen_PSet(X, Y)
	' 在位图阵列上画点
	if X >= 0 And X < PicWidth And Y >= 0 And Y < PicHeight then Buf(Y, X) = 1
end sub

sub CDGen_Line(X1, Y1, X2, Y2)
	' 在位图阵列上画线
	Dim DX, DY, DeltaT, i

	DX = X2 - X1
	DY = Y2 - Y1
	if Abs(DX) > Abs(DY) then DeltaT = Abs(DX) Else DeltaT = Abs(DY)
	if DeltaT = 0 then
		CDGen_PSet CInt(X1),CInt(Y1)
	Else
		For i = 0 To DeltaT
			CDGen_PSet CInt(X1 + DX * i / DeltaT), CInt(Y1 + DY * i / DeltaT)
		Next
	end if
end sub

sub CDGen_FowardDraw(nLength)
	' 按当前光笔方向绘制指定长度并移动光笔，正数表示从左向右/从上向下绘制，负数表示从右向左/从下向上绘制
	nLength = nLength * (1 + (Rnd * 2 - 1) * nLengthRandom / 100)
	ReDim Preserve Lines(3, LineCount)
	Lines(0, LineCount) = CursorX
	Lines(1, LineCount) = CursorY
	CursorX = CursorX + DirX * nLength
	CursorY = CursorY + DirY * nLength
	Lines(2, LineCount) = CursorX
	Lines(3, LineCount) = CursorY
	LineCount = LineCount + 1
end sub

sub CDGen_SetDirection(nAngle)
	' 按指定角度设定画笔方向, 正数表示相对当前方向顺时针改变方向，负数表示相对当前方向逆时针改变方向
	Dim DX, DY

	nAngle = (nAngle + (Rnd * 2 - 1) * nAngleRandom) / 180 * 3.1415926
	DX = DirX
	DY = DirY
	DirX = DX * Cos(nAngle) - DY * Sin(nAngle)
	DirY = DX * Sin(nAngle) + DY * Cos(nAngle)
end sub

sub CDGen_MoveToMiddle(nActionIndex, nPercent)
	' 将画笔光标移动到指定动作的中间点上，nPercent为中间位置的百分比
	Dim DeltaX, DeltaY

	DeltaX = Lines(2, nActionIndex) - Lines(0, nActionIndex)
	DeltaY = Lines(3, nActionIndex) - Lines(1, nActionIndex)
	CursorX = Lines(0, nActionIndex) + DeltaX * nPercent / 100
	CursorY = Lines(1, nActionIndex) + DeltaY * Abs(DeltaY) * nPercent / 100
end sub

sub CDGen_MoveCursor(nActionIndex)
	' 将画笔光标移动到指定动作的起始点上
	CursorX = Lines(0, nActionIndex)
	CursorY = Lines(1, nActionIndex)
end sub

sub CDGen_Close(nActionIndex)
	' 将当前光笔位置与指定动作的起始点闭合并移动光笔
	ReDim Preserve Lines(3, LineCount)
	Lines(0, LineCount) = CursorX
	Lines(1, LineCount) = CursorY
	CursorX = Lines(0, nActionIndex)
	CursorY = Lines(1, nActionIndex)
	Lines(2, LineCount) = CursorX
	Lines(3, LineCount) = CursorY
	LineCount = LineCount + 1
end sub

sub CDGen_CloseToMiddle(nActionIndex, nPercent)
	' 将当前光笔位置与指定动作的中间点闭合并移动光笔，nPercent为中间位置的百分比
	Dim DeltaX, DeltaY

	ReDim Preserve Lines(3, LineCount)
	Lines(0, LineCount) = CursorX
	Lines(1, LineCount) = CursorY
	DeltaX = Lines(2, nActionIndex) - Lines(0, nActionIndex)
	DeltaY = Lines(3, nActionIndex) - Lines(1, nActionIndex)
	CursorX = Lines(0, nActionIndex) + Sgn(DeltaX) * Abs(DeltaX) * nPercent / 100
	CursorY = Lines(1, nActionIndex) + Sgn(DeltaY) * Abs(DeltaY) * nPercent / 100
	Lines(2, LineCount) = CursorX
	Lines(3, LineCount) = CursorY
	LineCount = LineCount + 1
end sub

sub CDGen_Flush(X0, Y0)
	' 按照当前的画笔动作序列绘制位图点阵
	Dim MaxX, MinX, MaxY, MinY
	Dim DeltaX, DeltaY, StepX, StepY, OffsetX, OffsetY
	Dim i

	MaxX = MinX = MaxY = MinY = 0
	For i = 0 To LineCount - 1
		if MaxX < Lines(0, i) then MaxX = Lines(0, i)
		if MaxX < Lines(2, i) then MaxX = Lines(2, i)
		if MinX > Lines(0, i) then MinX = Lines(0, i)
		if MinX > Lines(2, i) then MinX = Lines(2, i)
		if MaxY < Lines(1, i) then MaxY = Lines(1, i)
		if MaxY < Lines(3, i) then MaxY = Lines(3, i)
		if MinY > Lines(1, i) then MinY = Lines(1, i)
		if MinY > Lines(3, i) then MinY = Lines(3, i)
	Next
	DeltaX = MaxX - MinX
	DeltaY = MaxY - MinY
	if DeltaX = 0 then DeltaX = 1
	if DeltaY = 0 then DeltaY = 1
	MaxX = MinX
	MaxY = MinY
	if DeltaX > DeltaY then
		StepX = (nPixelWidth - 2) / DeltaX
		StepY = (nPixelHeight - 2) / DeltaX
		OffsetX = 0
		OffsetY = (DeltaX - DeltaY) / 2
	Else
		StepX = (nPixelWidth - 2) / DeltaY
		StepY = (nPixelHeight - 2) / DeltaY
		OffsetX = (DeltaY - DeltaX) / 2
		OffsetY = 0
	end if
	For i = 0 To LineCount - 1
		Lines(0, i) = Round((Lines(0, i) - MaxX + OffsetX) * StepX, 0)
		Lines(1, i) = Round((Lines(1, i) - MaxY + OffsetY) * StepY, 0)
		Lines(2, i) = Round((Lines(2, i) - MinX + OffsetX) * StepX, 0)
		Lines(3, i) = Round((Lines(3, i) - MinY + OffsetY) * StepY, 0)
		CDGen_Line Lines(0, i) + X0 + 1, Lines(1, i) + Y0 + 1, Lines(2, i) + X0 + 1, Lines(3, i) + Y0 + 1
	Next
end sub

sub CDGen_Char(cChar, X0, Y0)
	' 在指定坐标处生成指定字符的位图阵列
	CDGen_Reset
	Select Case cChar
	Case "0"
		CDGen_SetDirection -60                            ' 逆时针60度(相对于垂直线)
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection -60                            ' 逆时针60度
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw 1.5                              ' 绘制1.5个单位
		CDGen_SetDirection -60                            ' 逆时针60度
		CDGen_FowardDraw 0.7                              ' 绘制0.7个单位
		CDGen_SetDirection -60                            ' 顺时针120度
		CDGen_FowardDraw 0.7                              ' 绘制0.7个单位
		CDGen_Close 0                                     ' 封闭当前笔与第0笔(0开始)
	Case "1"
		CDGen_SetDirection -90                            ' 逆时针90度(相对于垂直线)
		CDGen_FowardDraw 0.5                              ' 绘制0.5个单位
		CDGen_MoveToMiddle 0, 50                          ' 移动画笔的位置到第0笔(0开始)的50%处
		CDGen_SetDirection 90                             ' 逆时针90度
		CDGen_FowardDraw -1.4                             ' 反方向绘制1.4个单位
		CDGen_SetDirection 30                             ' 逆时针30度
		CDGen_FowardDraw 0.4                              ' 绘制0.4个单位
	Case "2"
		CDGen_SetDirection 45                             ' 顺时针45度(相对于垂直线)
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection -120                           ' 逆时针120度
		CDGen_FowardDraw 0.4                              ' 绘制0.4个单位
		CDGen_SetDirection 60                             ' 顺时针60度
		CDGen_FowardDraw 0.6                              ' 绘制0.6个单位
		CDGen_SetDirection 60                             ' 顺时针60度
		CDGen_FowardDraw 1.6                              ' 绘制1.6个单位
		CDGen_SetDirection -135                           ' 逆时针135度
		CDGen_FowardDraw 1.0                              ' 绘制1.0个单位
	Case "3"
		CDGen_SetDirection -90                            ' 逆时针90度(相对于垂直线)
		CDGen_FowardDraw 0.8                              ' 绘制0.8个单位
		CDGen_SetDirection 135                            ' 顺时针135度
		CDGen_FowardDraw 0.8                              ' 绘制0.8个单位
		CDGen_SetDirection -120                           ' 逆时针120度
		CDGen_FowardDraw 0.6                              ' 绘制0.6个单位
		CDGen_SetDirection 80                             ' 顺时针80度
		CDGen_FowardDraw 0.5                              ' 绘制0.5个单位
		CDGen_SetDirection 60                             ' 顺时针60度
		CDGen_FowardDraw 0.5                              ' 绘制0.5个单位
		CDGen_SetDirection 60                             ' 顺时针60度
		CDGen_FowardDraw 0.5                              ' 绘制0.5个单位
	Case "4"
		CDGen_SetDirection 20                             ' 顺时针20度(相对于垂直线)
		CDGen_FowardDraw 0.8                              ' 绘制0.8个单位
		CDGen_SetDirection -110                           ' 逆时针110度
		CDGen_FowardDraw 1.2                              ' 绘制1.2个单位
		CDGen_MoveToMiddle 1, 60                          ' 移动画笔的位置到第1笔(0开始)的60%处
		CDGen_SetDirection 90                             ' 顺时针90度
		CDGen_FowardDraw 0.7                              ' 绘制0.7个单位
		CDGen_MoveCursor 2                                ' 移动画笔到第2笔(0开始)的开始处
		CDGen_FowardDraw -1.5                             ' 反方向绘制1.5个单位
	Case "5"
		CDGen_SetDirection 90                             ' 顺时针90度(相对于垂直线)
		CDGen_FowardDraw 1.0                              ' 绘制1.0个单位
		CDGen_SetDirection -90                            ' 逆时针90度
		CDGen_FowardDraw 0.8                              ' 绘制0.8个单位
		CDGen_SetDirection -90                            ' 逆时针90度
		CDGen_FowardDraw 0.8                              ' 绘制0.8个单位
		CDGen_SetDirection 30                             ' 顺时针30度
		CDGen_FowardDraw 0.4                              ' 绘制0.4个单位
		CDGen_SetDirection 60                             ' 顺时针60度
		CDGen_FowardDraw 0.4                              ' 绘制0.4个单位
		CDGen_SetDirection 30                             ' 顺时针30度
		CDGen_FowardDraw 0.5                              ' 绘制0.5个单位
		CDGen_SetDirection 60                             ' 顺时针60度
		CDGen_FowardDraw 0.8                              ' 绘制0.8个单位
	Case "6"
		CDGen_SetDirection -60                            ' 逆时针60度(相对于垂直线)
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection -60                            ' 逆时针60度
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw 1.5                              ' 绘制1.5个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw 0.7                              ' 绘制0.7个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw 0.5                              ' 绘制0.5个单位
		CDGen_CloseToMiddle 2, 50                         ' 将当前画笔位置与第2笔(0开始)的50%处封闭
	Case "7"
		CDGen_SetDirection 180                            ' 顺时针180度(相对于垂直线)
		CDGen_FowardDraw 0.3                              ' 绘制0.3个单位
		CDGen_SetDirection 90                             ' 顺时针90度
		CDGen_FowardDraw 0.9                              ' 绘制0.9个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw 1.3                              ' 绘制1.3个单位
	Case "8"
		CDGen_SetDirection -60                            ' 逆时针60度(相对于垂直线)
		CDGen_FowardDraw -0.8                             ' 反方向绘制0.8个单位
		CDGen_SetDirection -60                            ' 逆时针60度
		CDGen_FowardDraw -0.8                             ' 反方向绘制0.8个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw 0.8                              ' 绘制0.8个单位
		CDGen_SetDirection 110                            ' 顺时针110度
		CDGen_FowardDraw -1.5                             ' 反方向绘制1.5个单位
		CDGen_SetDirection -110                           ' 逆时针110度
		CDGen_FowardDraw 0.9                              ' 绘制0.9个单位
		CDGen_SetDirection 60                             ' 顺时针60度
		CDGen_FowardDraw 0.8                              ' 绘制0.8个单位
		CDGen_SetDirection 60                             ' 顺时针60度
		CDGen_FowardDraw 0.8                              ' 绘制0.8个单位
		CDGen_SetDirection 60                             ' 顺时针60度
		CDGen_FowardDraw 0.9                              ' 绘制0.9个单位
		CDGen_SetDirection 70                             ' 顺时针70度
		CDGen_FowardDraw 1.5	                            ' 绘制1.5个单位
		CDGen_Close 0                                     ' 封闭当前笔与第0笔(0开始)
	Case "9"
		CDGen_SetDirection 120                            ' 逆时针60度(相对于垂直线)
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection -60                            ' 逆时针60度
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection -60                            ' 顺时针120度
		CDGen_FowardDraw -1.5                              ' 绘制1.5个单位
		CDGen_SetDirection -60                            ' 顺时针120度
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection -60                            ' 顺时针120度
		CDGen_FowardDraw -0.7                              ' 绘制0.7个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw 0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection -60                            ' 顺时针120度
		CDGen_FowardDraw 0.5                              ' 绘制0.5个单位
		CDGen_CloseToMiddle 2, 50                         ' 将当前画笔位置与第2笔(0开始)的50%处封闭
	' 以下为字母的矢量动作，有兴趣的可以继续
	Case "A"
		CDGen_SetDirection -(Rnd * 20 + 150)              ' 逆时针150-170度(相对于垂直线)
		CDGen_FowardDraw Rnd * 0.2 + 1.1                  ' 绘制1.1-1.3个单位
		CDGen_SetDirection Rnd * 20 + 140                 ' 顺时针140-160度
		CDGen_FowardDraw Rnd * 0.2 + 1.1                  ' 绘制1.1-1.3个单位
		CDGen_MoveToMiddle 0, 30                          ' 移动画笔的位置到第1笔(0开始)的30%处
		CDGen_CloseToMiddle 1, 70                         ' 将当前画笔位置与第1笔(0开始)的70%处封闭
	Case "B"
		CDGen_SetDirection -(Rnd * 20 + 50)               ' 逆时针50-70度(相对于垂直线)
		CDGen_FowardDraw Rnd * 0.4 + 0.8                  ' 绘制0.8-1.2个单位
		CDGen_SetDirection Rnd * 20 + 110                 ' 顺时针110-130度
		CDGen_FowardDraw Rnd * 0.2 + 0.6                  ' 绘制0.6-0.8个单位
		CDGen_SetDirection -(Rnd * 20 + 110)              ' 逆时针110-130度
		CDGen_FowardDraw Rnd * 0.2 + 0.6                  ' 绘制0.6-0.8个单位
		CDGen_SetDirection Rnd * 20 + 110                 ' 顺时针110-130度
		CDGen_FowardDraw Rnd * 0.4 + 0.8                  ' 绘制0.8-1.2个单位
		CDGen_Close 0                                     ' 封闭当前笔与第1笔(0开始)
	Case "C"
		CDGen_SetDirection -60                            ' 逆时针60度(相对于垂直线)
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection -60                            ' 逆时针60度
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw 1.5                              ' 绘制1.5个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw -0.7                             ' 反方向绘制0.7个单位
		CDGen_SetDirection 120                            ' 顺时针120度
		CDGen_FowardDraw 0.7                              ' 绘制0.7个单位
	end Select
	CDGen_Flush X0, Y0
end sub

sub CDGen_Blur()
	' 对产生的位图进行柔化处理
	Dim i, j

	For j = 1 To PicHeight - 2
		For i = 1 To PicWidth - 2
			if Buf(j, i) = 0 then
				if ((Buf(j, i - 1) Or Buf(j + 1, i)) And 1) <> 0 then
					' 如果当前点是空白点，且上下左右四个点中有一个点是有色点，则该点做柔化处理
					Buf(j, i) = 2
				end if
			end if
		Next
	Next
end sub

sub CDGen_NoisyLine()
	Dim i
	For i=1 To nNoisyLineCount
		CDGen_Line Rnd * PicWidth, Rnd * PicHeight, Rnd * PicWidth, Rnd * PicHeight
	Next
end sub

sub CDGen_NoisyDot()
	' 对产生的位图进行噪点处理
	Dim i, j, NoisyDot, CurDot

	For j = 0 To PicHeight - 1
		For i = 0 To PicWidth - 1
			if Buf(j, i) <> 0 then
				if Rnd < nColorNoisyDotOdds then
					Buf(j, i) = 0
				Else
					Buf(j, i) = nSaturation
				end if
			Else
				if Rnd < nBlankNoisyDotOdds then
					Buf(j, i) = nSaturation
				Else
					Buf(j, i) = 0
				end if
			end if
		Next
	Next
end sub

sub CDGen()
	' 生成位图阵列
	Dim i, Ch, w, x, y

	DigtalStr = ""
	CDGen_Clear
	w = nImgWidth / nCharCount

	For i = 0 To nCharCount - 1
		nPixelWidth = w * (1 + (Rnd * 2 - 1) * nCharWidthRandom / 100)
		nPixelHeight = nImgHeight * (1 - Rnd * nCharHeightRandom / 100)
		x = nSpaceX + w * (i + (Rnd * 2 - 1) * nPositionXRandom / 100)
		y = nSpaceY + nImgHeight * (Rnd * 2 - 1) * nPositionYRandom / 100

		Ch = Mid(cCharSet, Int(Rnd * Len(cCharSet)) + 1, 1)
		DigtalStr = DigtalStr + Ch

		CDGen_Char Ch, x, y
	Next
	CDGen_Blur
	CDGen_NoisyLine
	CDGen_NoisyDot
end sub

function HSBToRGB(vH, vS, vB)
	' 将颜色值由HSB转换为RGB
	Dim aRGB(3), RGB1st, RGB2nd, RGB3rd
	Dim nH, nS, nB
	Dim lH, nF, nP, nQ, nT

	vH = (vH Mod 360)
	if vS > 100 then
		vS = 100
	elseIf vS < 0 then
		vS = 0
	end if
	if vB > 100 then
		vB = 100
	elseIf vB < 0 then
		vB = 0
	end if
	if vS > 0 then
		nH = vH / 60
		nS = vS / 100
		nB = vB / 100
		lH = Int(nH)
		nF = nH - lH
		nP = nB * (1 - nS)
		nQ = nB * (1 - nS * nF)
		nT = nB * (1 - nS * (1 - nF))
		Select Case lH
		Case 0
			aRGB(0) = nB * 255
			aRGB(1) = nT * 255
			aRGB(2) = nP * 255
		Case 1
			aRGB(0) = nQ * 255
			aRGB(1) = nB * 255
			aRGB(2) = nP * 255
		Case 2
			aRGB(0) = nP * 255
			aRGB(1) = nB * 255
			aRGB(2) = nT * 255
		Case 3
			aRGB(0) = nP * 255
			aRGB(1) = nQ * 255
			aRGB(2) = nB * 255
		Case 4
			aRGB(0) = nT * 255
			aRGB(1) = nP * 255
			aRGB(2) = nB * 255
		Case 5
			aRGB(0) = nB * 255
			aRGB(1) = nP * 255
			aRGB(2) = nQ * 255
		end Select
	Else
		aRGB(0) = (vB * 255) / 100
		aRGB(1) = aRGB(0)
		aRGB(2) = aRGB(0)
	end if
	HSBToRGB = ChrB(Round(aRGB(2), 0)) & ChrB(Round(aRGB(1), 0)) & ChrB(Round(aRGB(0), 0))
end function

sub createVerifyCode(pSN)
	Dim i, j, CurColorHue

	call CDGen()
	Session(pSN) = DigtalStr	'记录入Session

	Dim FileSize, PicDataSize
	PicDataSize = PicWidth * PicHeight * 3
	FileSize = PicDataSize + 54

	' 输出BMP文件信息头
	Response.BinaryWrite ChrB(66) & ChrB(77) & ChrB(FileSize Mod 256) & ChrB((FileSize \ 256) Mod 256) & ChrB((FileSize \ 256 \ 256) Mod 256) & ChrB(FileSize \ 256 \ 256 \ 256) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(54) & ChrB(0) & ChrB(0) & ChrB(0)

	' 输出BMP位图信息头
	Response.BinaryWrite ChrB(40) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(PicWidth Mod 256) & ChrB((PicWidth \ 256) Mod 256) & ChrB((PicWidth \ 256 \ 256) Mod 256) & ChrB(PicWidth \ 256 \ 256 \ 256) & ChrB(PicHeight Mod 256) & ChrB((PicHeight \ 256) Mod 256) & ChrB((PicHeight \ 256 \ 256) Mod 256) & ChrB(PicHeight \ 256 \ 256 \ 256) & ChrB(1) & ChrB(0) & ChrB(24) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(PicDataSize Mod 256) & ChrB((PicDataSize \ 256) Mod 256) & ChrB((PicDataSize \ 256 \ 256) Mod 256) & ChrB(PicDataSize \ 256 \ 256 \ 256) & ChrB(18) & ChrB(11) & ChrB(0) & ChrB(0) & ChrB(18) & ChrB(11) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(0) & ChrB(0)

	' 逐点输出位图阵列
	if nColorHue = -1 then
		CurColorHue = Int(Rnd * 360)
	elseIf nColorHue <> -2 then
		CurColorHue = nColorHue
	end if
	For j = 0 To PicHeight - 1
		For i = 0 To PicWidth - 1
			if nColorHue = -2 then
				Response.BinaryWrite HSBToRGB(0, 0, 100 - Buf(PicHeight - 1 - j, i))
			Else
				Response.BinaryWrite HSBToRGB(CurColorHue, Buf(PicHeight - 1 - j, i), 100)
			end if
		Next
	Next
end sub
%>