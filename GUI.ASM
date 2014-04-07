;MASMPlus 代码模板 - 普通的 Windows 程序代码

.386
.Model Flat, StdCall
Option Casemap :None

Include windows.inc
Include user32.inc
Include kernel32.inc
Include gdi32.inc
include winmm.inc
includelib winmm.lib
includelib gdi32.lib
IncludeLib user32.lib
IncludeLib kernel32.lib
include macro.asm
include gdiplus.inc
includelib gdiplus.lib
include ole32.inc
includelib ole32.lib
gdiplusLoadBitmapFromResource proto :HMODULE, :LPSTR, :LPSTR, :DWORD
;定义飞机
Hero struct
	x DWORD ?
	y DWORD ?
	status DWORD ?
Hero ends
;定义子弹
Bullet struct
	status DWORD ?
	x DWORD ?
	y DWORD ?
	curtype DWORD ?
Bullet ends
;定义敌人
PObject struct
	status DWORD 0;0 dead, 1 active
	x DWORD ?
	y DWORD 0
	speed DWORD 1;initial 1
	hitnum DWORD 0
	curtype DWORD 0;0 small plane, 1 big plane, 2 boss plane, 3 bullet_zero, 4, bullet_one
PObject ends
;定义png图像上各个元素的位置
location struct
	x DWORD ?
	y DWORD ?
	w DWORD ?
	h DWORD ?
location ends


	WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
	WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
	;初始化游戏界面
	initGame proto hWin:DWORD, stRect:RECT
	;画出某个icon(x, y)中心坐标，loc为相应对象的location对象
	drawIcon proto g:HANDLE, png:DWORD, x:DWORD, y:DWORD, loc:location, :DWORD
	;打印某个数字
	shownum proto hWin:DWORD, num:DWORD
	;绘制子弹
	drawBullets proto hWin:DWORD, stRect:RECT
	;绘制敌机
	drawEnemies proto hWin:DWORD, stRect:RECT
	;绘制所有物体
	drawAllObjects proto g:HANDLE, hWin:DWORD, stRect:RECT
	;敌机与玩家碰撞检测
	detectCollideWithPlayer proto hWin:DWORD, stRect:RECT
	;敌机与子弹的碰撞检测
	detectCollideWithBullets proto hWin:DWORD, stRect:RECT
	;检测敌机周围有没有子弹
	detectBulletAroundEnemies proto hWin:DWORD, stRect:RECT, enemyX: DWORD, enemyY: DWORD
	;清空子弹和敌机
	clearScreen proto hWin:DWORD, stRect:RECT
	;
	drawAllExplodsion proto, graphics:HANDLE, hWin:DWORD
.DATA
	szClassName db "MASMPlus_Class",0
	hdc HDC ?
	path BYTE "bg_02.bmp", 0
	pngpath BYTE "plane.png", 0
	btnPngPath BYTE "images/button_bg.png", 0
	pstatus DWORD 0;0表示开始，1表示大战，2表示结束
	pbutton BYTE "button", 0
	pstart BYTE "START", 0
	;初始化gdi+对象
	gdiplusToken	dd ?
	gdiplusSInput	GdiplusStartupInput <1, NULL, FALSE, FALSE>
	;png图像的数据
	pngImage		dd NULL
	btnPngImage dd NULL
	pngType		db "PNG", 0
	bkImage 		dd NULL
	;用于调试格式化打印数字
	;--------------temp data to print
	stri BYTE "%i", 0
	temp BYTE 20 dup(0)
	;------------element id register------------
	startButtonId DWORD 10
	;------------planes-----------------
	Me Hero <>
	Explodsion COORD 40 dup(<>)
	ExplodsionNum DWORD 0
	enemies PObject 40 dup(<>)
	bullets Bullet 40 dup(<>)
	countBullets DWORD ? ;定时器，每8下发一次子弹
	countSEnemies DWORD ? ;定时器，每32
	countMEnemies DWORD ? ;定时器，每64
	countBEnemies DWORD ? ;定时器，每128
	clientWidth DWORD ? ;屏幕的长
	clientHeight DWORD ? ;屏幕的宽
	enemyNum DWORD 40 ;敌机数量的数组大小
	bulletNum DWORD 40;子弹数量的数组大小 
	;TotalNum DWORD 200;PlaneYou 使用的数量
	
	;------------png coord----------
	bomb_add location <144, 134, 29, 46>
	bomb_icon location <184,117, 30, 29>
	bullet_zero location <112, 2, 9, 17>
	bullet_one location <66, 238, 8, 15>
	bullet_add location <112, 117, 30, 46>
	ememy_b location <2, 2, 108, 164>
	ememy_m location <130, 2, 69, 89>
	ememy_s location <201, 88, 39, 27>
	explosion_one location <216, 117, 26, 26>
	explosion_two location <144, 93, 38, 39>
	explosion_three location <201, 44, 40, 42>
	hero_one location <66, 168, 62, 68>
	hero_two location <2, 168, 62, 75>
	pause_button location <175, 148, 22, 23>
	resume_buttion location <216, 145, 25, 27>
	smoke_one location <201, 2, 48, 20>
	smoke_two location <201, 24, 48, 18>
.DATA?
	hInstance	dd ?

.CODE
START:

	invoke GetModuleHandle,NULL
	mov hInstance,eax
	invoke	GdiplusStartup, addr gdiplusToken, addr gdiplusSInput, NULL
	invoke WinMain,hInstance,NULL,NULL,SW_SHOWDEFAULT
	invoke	GdiplusShutdown, gdiplusToken
	invoke ExitProcess,0

WinMain proc hInst:DWORD,hPrevInst:DWORD,CmdLine:DWORD,CmdShow:DWORD
	LOCAL wc   :WNDCLASSEX
	LOCAL msg  :MSG
	local hWnd :HWND
	
	
	mov wc.cbSize,sizeof WNDCLASSEX
	mov wc.style,CS_HREDRAW or CS_VREDRAW or CS_BYTEALIGNWINDOW
	mov wc.lpfnWndProc,offset WndProc
	mov wc.cbClsExtra,NULL
	mov wc.cbWndExtra,NULL
	push hInst
	pop wc.hInstance
	mov wc.hbrBackground,COLOR_BTNFACE+1
	mov wc.lpszMenuName,NULL
	mov wc.lpszClassName,offset szClassName
	invoke LoadIcon, hInst, 100
	mov wc.hIcon, eax
	invoke LoadCursor, NULL,IDC_ARROW
	mov wc.hCursor, eax
	mov wc.hIconSm, 0

	invoke RegisterClassEx, ADDR wc
	invoke CreateWindowEx,NULL,ADDR szClassName,CTXT("Air Fighting"),WS_OVERLAPPEDWINDOW,460,20, 450, 675,NULL,NULL,hInst,NULL
	mov hWnd,eax
	invoke ShowWindow,hWnd, SW_SHOWNORMAL
	invoke UpdateWindow,hWnd
	
	StartLoop:
		invoke GetMessage,ADDR msg,NULL,0,0
			cmp eax, 0
			je ExitLoop
				invoke TranslateMessage, ADDR msg
				invoke DispatchMessage, ADDR msg
			jmp StartLoop
	ExitLoop:
	invoke KillTimer, hWnd, 1
mov eax,msg.wParam
ret
WinMain endp

WndProc proc hWin:DWORD,uMsg:DWORD,wParam :DWORD,lParam :DWORD
	local stPs:PAINTSTRUCT
	local stRect:RECT
	local pbitmap:HBITMAP
	local sbitmap:HBITMAP
	local hdcbuffer:HDC
	local graphics:HANDLE
	local pbrush:HBRUSH
	local nhb:DWORD

	.if uMsg==WM_CREATE
		mov eax, WS_CHILD
		or eax, WS_VISIBLE
		or eax, BS_DEFPUSHBUTTON
		invoke CreateWindowEx, NULL, offset pbutton,CTXT("start"), eax, 180,400, 90, 50,hWin,startButtonId,hInstance,NULL
		;invoke CreateWindow, CTXT("button"), CTXT("start"), , 200, 200, 200, 150, hWin, 1, hInstance, NULL
		;设置定时器
		invoke SetTimer, hWin, 1, 30, NULL
		;加载图像资源
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2002, addr pngType, addr bkImage
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2001, addr pngType, addr pngImage
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2000, addr pngType, addr btnPngImage
		
	.elseif uMsg == WM_DESTROY
		invoke PostQuitMessage,NULL
	.elseif uMsg == WM_COMMAND
		mov eax, wParam
		shr eax, 16
		;button clicked 
		.if ax == BN_CLICKED
			mov eax, wParam
			and eax, 0000ffffh
			;the button is start button
			.if eax == startButtonId
				invoke initGame, hWin, stRect
			.endif
		.endif
		mov eax, 0
;处理绘制事件
	.elseif uMsg == WM_PAINT
		invoke BeginPaint, hWin, ADDR stPs
		mov eax, stPs.hdc
		mov hdc, eax
		mov eax, stPs.rcPaint.right
	;双缓冲
		invoke GetClientRect, hWin, ADDR stRect
	
		invoke CreateCompatibleDC, hdc
		mov hdcbuffer, eax
		invoke SaveDC, hWin
		mov nhb, eax
	;initGame之后才有clientWidth和clientHeight的值
		mov eax, stRect.right
		sub eax, stRect.left
		mov clientWidth, eax
		mov ecx, stRect.bottom
		sub ecx, stRect.top
		mov clientHeight, ecx
		invoke CreateCompatibleBitmap, hdc, eax, ecx
		
		mov pbitmap, eax
		
		invoke SelectObject, hdcbuffer, pbitmap
		
		invoke GdipCreateFromHDC, hdcbuffer, addr graphics
	
		invoke GdipDrawImageI, graphics, bkImage, 0, 0
		;invoke GdipDrawImageI, graphics, btnPngImage, 120, 200
		
		
		
		.if pstatus == 0	
			
		
		.elseif pstatus == 1
			invoke drawIcon, graphics, pngImage, Me.x, Me.y, hero_two, hWin
			invoke drawAllObjects, graphics, hWin, stRect			;绘制除玩家外所有物体
			.if ExplodsionNum != 0
				invoke drawAllExplodsion, graphics, hWin
			.endif
		.elseif pstatus == 2			 ;游戏结束
			;玩家飞机的爆炸效果绘制开始
			invoke drawIcon, graphics, pngImage, Me.x, Me.y, explosion_three, hWin
			invoke drawAllObjects, graphics, hWin, stRect			;绘制除玩家外所有物体
			.if ExplodsionNum != 0
				invoke drawAllExplodsion, graphics, hWin
			.endif
			mov eax, clientWidth
			mov ecx, clientHeight
			
			invoke BitBlt, hdc, 0, 0, eax, ecx, hdcbuffer, 0, 0, SRCCOPY

			invoke	GdipDeleteGraphics, graphics
			invoke DeleteObject, pbitmap
			
			invoke DeleteDC, hdcbuffer
			
			invoke EndPaint, hWin, ADDR stPs
			;玩家飞机的爆炸效果绘制完毕
			invoke mciSendString, CTXT("close shootmp3"), NULL, 0, 0 ;关闭声音
			invoke KillTimer, hWin, 1;关闭计时器
			invoke MessageBox, hWin, CTXT("Try Again"), CTXT("Try Again"), MB_YESNO;是否重来
			cmp eax, 6
			jne    Thankyou
			invoke clearScreen, hWin, stRect ;点击确定
			invoke SetTimer, hWin, 1, 30, NULL
        	mov eax, 1
        	mov pstatus, eax
        	invoke initGame, hWin, stRect    
        	ret
    		Thankyou:								;点击取消
    			invoke MessageBox, hWin, CTXT("Thank You"), CTXT("Thank You"), MB_OK
    			mov eax, 0
    			mov pstatus, eax
    			ret
		.endif
		
		mov eax, clientWidth
		mov ecx, clientHeight
		;invoke shownum, hWin, eax
		invoke BitBlt, hdc, 0, 0, eax, ecx, hdcbuffer, 0, 0, SRCCOPY

		invoke	GdipDeleteGraphics, graphics
		invoke DeleteObject, pbitmap
		
		invoke DeleteDC, hdcbuffer
		
		invoke EndPaint, hWin, ADDR stPs
	;处理键盘事件
	.elseif uMsg == WM_KEYDOWN
		.if wParam == VK_LEFT
			;左边缘判断
			.if Me.x <= 30 
				ret
			.endif
			;向左移动
			sub Me.x, 18
			.if eax == 0
				invoke MessageBox, hWin, CTXT("H"), CTXT("H"), MB_OK
			.endif
		.elseif wParam == VK_RIGHT
			;右边缘判断
			mov eax, clientWidth
			sub eax, 48
			.if Me.x >= eax 
				ret
			.endif
			;向右移动
			add Me.x, 18
			.if eax == 0
				invoke MessageBox, hWin, CTXT("H"), CTXT("H"), MB_OK
			.endif
		.elseif wParam == VK_UP
			;上边缘判断
			.if Me.y == 38
				ret
			.endif
			;向上移动
			sub Me.y, 6
			.if eax == 0
				invoke MessageBox, hWin, CTXT("H"), CTXT("H"), MB_OK
			.endif
		.elseif wParam == VK_DOWN
			;下边缘判断
			mov eax, clientHeight
			sub eax, 60
			.if Me.y >= eax
				ret
			.endif
			;向下移动
			add Me.y, 6
			.if eax == 0
				invoke MessageBox, hWin, CTXT("H"), CTXT("H"), MB_OK
			.endif
		.elseif wParam == 13 ;按ENTER键开始游戏
			invoke initGame, hWin, stRect
		.endif
	;处理时钟事件
	.elseif uMsg == WM_TIMER
		
		.if pstatus == 1
			
			;生成子弹和敌机
			invoke drawEnemies, hWin, stRect
			invoke drawBullets, hWin, stRect
			
			;判断敌机与子弹是否碰撞，若碰撞绘制爆炸效果
			invoke detectCollideWithBullets, hWin, stRect
			;判断飞机与敌机是否碰撞，若碰撞绘制爆炸效果
			invoke detectCollideWithPlayer, hWin, stRect
			
		.endif
		;仅在时钟中绘制图形
		invoke GetClientRect, hWin, addr stRect 
		invoke InvalidateRect, hWin, addr stRect, 0
		invoke SendMessage, hWin, WM_PAINT, NULL, NULL

	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif

	ret
WndProc endp

drawIcon proc g:HANDLE, png:DWORD, x:DWORD, y:DWORD, loc:location, hWin:DWORD 
	local Mdx:DWORD
	local Mdy:DWORD
	push eax
	push ecx
	
	mov eax, loc.w
	shr eax, 1
	mov ecx, x
	mov Mdx, ecx
	

	sub Mdx, eax
	mov eax, loc.h
	shr eax, 1
	mov ecx, y
	mov Mdy, ecx
	sub Mdy, eax

	invoke GdipDrawImagePointRectI, g, png, Mdx, Mdy, loc.x, loc.y, loc.w, loc.h, 2
	pop ecx
	pop eax
	ret
drawIcon endp

shownum proc hWin:DWORD, num:DWORD
	;show num code
	invoke wsprintf, OFFSET temp, OFFSET stri, num
	invoke MessageBox, hWin, OFFSET temp, OFFSET temp, MB_OK
	ret
shownum endp

initGame proc hWin:DWORD, stRect:RECT
	;播放声音
	invoke mciSendString, CTXT("open explosion.mp3 alias explosionmp3 type mpegvideo"), NULL, 0, 0
	invoke mciSendString, CTXT("open small_plane_killed.wav alias small type mpegvideo"), NULL, 0, 0
	invoke mciSendString, CTXT("open shoot.mp3 alias shootmp3 type mpegvideo"), NULL, 0, 0
	invoke mciSendString, CTXT("open game_music.wav alias game type mpegvideo"), NULL, 0, 0
	invoke mciSendString, CTXT("open fire_bullet.wav alias game1 type mpegvideo"), NULL, 0, 0
	invoke mciSendString, CTXT("play game repeat"), NULL, 0, 0
	invoke mciSendString, CTXT("play game1 repeat"), NULL, 0, 0
	;mov ecx, 1000
	;L1:
	;inc eax
;	loop L1
;	invoke mciSendString, CTXT("play game1 repeat"), NULL, 0, 0
;	mov ecx, 1000
;	L2:
;	inc eax
;	loop L2
;	invoke mciSendString, CTXT("play game1 repeat"), NULL, 0, 0
	;invoke mciSendString, CTXT("play shootmp3 repeat"), NULL, 0, 0
	;invoke MessageBox, hWin,CTXT("hello"), CTXT("hello"), MB_OK
	invoke GetDlgItem, hWin, startButtonId
	.if eax == 0
		invoke MessageBox, hWin, CTXT("HELLO"), CTXT("HELLO"), MB_OK
	.endif
	;invoke DestroyWindow, eax
	invoke ShowWindow, eax, SW_HIDE
	mov pstatus, 1
	mov Me.x, 210
	mov Me.y, 520
	mov Me.status, 1
	;invoke UpdateWindow, hWin
	invoke SendMessage, hWin, WM_PAINT, NULL, NULL
	invoke InvalidateRect, hWin, NULL, 1
	;invoke MessageBox, hWin, CTXT("HELLO"), CTXT("HELLO"), MB_OK
	ret
initGame endp

drawBullets proc hWin:DWORD, stRect:RECT
	pushad
	inc countBullets
	mov esi, offset bullets
	mov ebx, SIZEOF Bullet
	mov ecx, bulletNum
	dec ecx
	mov eax, countBullets
	;----每8定时器发子弹
	;shr eax, 3
	.if eax == 8	
		mov eax, 0
		mov countBullets, eax ;定时器清零

	T0:
		mov eax, [esi]
		.if eax == 0
			mov eax, 1
			mov [esi], eax
			add esi, 4
			mov edx, Me.x
			add edx, 9
			mov [esi], edx
			add esi, 4
			mov edx, Me.y
			sub edx, 20
			mov [esi], edx
			add esi, 4
			mov eax, 0 
			mov [esi], eax
			add esi, 4
			
			jmp MOVELABEL1
		.elseif 
			add esi, 16
		.endif
		loop T0
	.else
		jmp T1
	.endif
	
	;子弹运动	
	MOVELABEL1:
		mov esi, offset bullets
		mov ecx, bulletNum
		dec ecx
	T1:
	
	mov eax, [esi]

	.if eax == 1
		mov eax, 8
		add esi, eax
		mov eax, [esi]
		sub eax, 12		;子弹运动速度
		.if eax < 9
			sub esi, 8 
			mov eax, 0
			mov [esi], eax
			add esi, 8
			mov eax, 0
			mov [esi], eax
		.else
			mov [esi], eax
		.endif
		add esi, 8
	.else
		add esi, 16		;跳过status为0的点
	.endif
	Loop T1
	
	popad
	ret
drawBullets endp


drawEnemies proc hWin:DWORD, stRect:RECT
	pushad
	inc countSEnemies
	mov esi, offset enemies
	mov ebx, SIZEOF PObject
	mov ecx, enemyNum
	dec ecx
	mov eax, countSEnemies
	;----每32时钟产生敌人
	;shr eax, 5
	.if eax == 32
		mov eax, 0
		mov countSEnemies, eax ;计时器清零
		invoke GetTickCount;用计时器模拟随机
		mov ebx, 61 ;乘以一个素数调整eax
		imul ebx
		mov ebx, clientWidth	;除以屏幕的长度
		sub ebx, 48
		div ebx			;余数存在edx中
	T2: ;找到第一个空余位置，新增一辆敌机
		mov eax, [esi]
		.if eax == 0
			mov eax, 1
			mov [esi], eax ;active
			add esi, 4
			add edx, 20
			mov [esi], edx ; x
			add esi, 4
			mov edx, 0		
			add edx, 20
			mov [esi], edx ; y
			add esi, 4
			mov eax, 1 ;敌机的速度为1，待调整
			mov [esi], eax ; speed
			add esi, 4
			mov eax, 1
			mov [esi], eax ; hitnum，表示被子弹击中多少次会爆炸
			add esi, 4
			invoke GetTickCount ;随机敌机的类型
			mov ebx, 2
			div ebx
			mov [esi], edx ; curtype
			add esi, 4
			jmp MOVELABLE2
		.elseif 
			add esi, 24
		.endif
		loop T2
	.else
		jmp T3
	.endif

	;移动已有敌机
MOVELABLE2:
	mov esi, offset enemies
	mov ecx, enemyNum
	dec ecx
T3:
	mov eax, [esi]
	.if eax == 1
		mov eax, 8
		add esi, eax   ;改变敌机的y值
		mov eax, [esi] 
		add eax, 6		;将y值加9（该值可根据飞机速度不同进行调整）
		;判断敌机是否飞出区域
		mov edx, clientHeight
		sub edx, 10
		.if eax > edx
			sub esi, 8 
			mov eax, 0
			mov [esi], eax
			add esi,8
			mov eax, 0
			mov [esi], eax
		.elseif
			mov [esi], eax
		.endif
		add esi, 16		;到下一个飞机的坐标
	.else
		add esi, 24		;跳过status为0的点
	.endif
	Loop T3
	popad
	ret
drawEnemies endp

drawAllObjects proc graphics:HANDLE, hWin:DWORD, stRect:RECT
	pushad
		;draw all bullets
		mov ecx, 40
		dec ecx
		mov esi, offset bullets
	P1:
		mov eax, [esi]
		.if eax == 1 ;共计16字节
			add esi, 4
			mov ebx, [esi]
			add esi, 4
			mov edx, [esi]
			invoke drawIcon, graphics, pngImage,  ebx, edx, bullet_one, hWin
			add esi, 8
		.elseif
			add esi, 16
		.endif
		Loop P1
		;draw all enemies
		mov ecx, enemyNum
		dec ecx
		mov esi, offset enemies
	E1:
		mov eax, [esi]
		.if eax == 1 ;敌机active，共计24字节
			add esi, 4
			mov ebx, [esi]
			add esi, 4
			mov edx, [esi]
			add esi, 12	
			mov eax, [esi]
			.if eax == 0 ;
				invoke drawIcon, graphics, pngImage,  ebx, edx, ememy_s, hWin
			.elseif eax == 1
				invoke drawIcon, graphics, pngImage,  ebx, edx, ememy_m, hWin
			.endif
			;invoke shownum, hWin, 1
			add esi, 4
		.elseif;敌机dead或未定义，跳过
			add esi, 24
		.endif
		dec ecx
		jne E1
	popad
	ret
drawAllObjects endp

detectCollideWithPlayer proc hWin:DWORD, stRect:RECT
	;循环当前所有的敌机位置，判断是否相撞
	pushad
	mov esi, offset enemies
	mov ecx, enemyNum
DETECT1:
	mov eax, [esi]
	.if eax == 1
		add esi, 4
		mov ebx, [esi]
		.if ebx > Me.x		;x轴绝对值
			sub ebx, Me.x
		.else
			mov eax, ebx
			mov ebx, Me.x
			sub ebx, eax
		.endif
		add esi, 4
		.if ebx<50
			mov edx, [esi]		;y轴绝对值
			.if edx > Me.y
				sub edx, Me.y
			.else
				mov eax, edx
				mov edx, Me.y
				sub edx, eax
			.endif
			.if edx < 50		;发生碰撞
				mov eax,2
				mov pstatus, eax
				invoke mciSendString, CTXT("seek explosionmp3 to start"), NULL, 0, 0 ;放完一次指针就会被移到末尾，因此播放前要先移到开头
				invoke mciSendString, CTXT("play explosionmp3"), NULL, 0, 0			
			.endif
		.endif
		add esi, 16			;数组中的下一个数
	.else
		add esi, 24
	.endif
	dec ecx
	jne DETECT1
	popad
	ret
detectCollideWithPlayer endp

detectCollideWithBullets proc hWin:DWORD, stRect:RECT

	pushad
	mov esi, offset enemies
	mov ecx, enemyNum
DETECT2:					;循环检查敌机
	mov eax, [esi]
	.if eax == 1
		add esi, 4
		mov ebx, [esi]		;x坐标存在ebx中
		add esi, 4
		mov edx, [esi]		;y坐标存在edx中
		;判断(x,y)附件有没有子弹，如果有，飞机和子弹都消失，子弹需在飞机前
		invoke detectBulletAroundEnemies, hWin, stRect, ebx, edx
		; eax=0表示有子弹， eax=1表示没子弹
		.if eax == 0
			sub esi, 8
			mov [esi], eax
			add esi, 8
			;在飞机消失处(ebx,edx)爆炸，维持30ms
			push ecx
			push eax
			mov ecx, offset Explodsion
			mov eax, ExplodsionNum
			shl eax, 2
	
			add ecx, eax
			mov [ecx], bx
			
			add ecx, 2
			mov [ecx], dx
			inc ExplodsionNum
			
			pop eax
			pop ecx
		.endif
		add esi, 16
	.else
		add esi, 24
	.endif
	dec ecx
	jne DETECT2
	popad
	ret
detectCollideWithBullets endp

detectBulletAroundEnemies proc hWin:DWORD, stRect:RECT, enemyX: DWORD, enemyY: DWORD
	push ecx
	push esi
	push ebx
	push edx
	
	mov esi, offset bullets
	mov ecx, bulletNum
DETECT3:
	mov eax, [esi]
	.if eax == 1
		add esi, 4
		mov ebx, [esi]		;x坐标存在ebx中
		add esi, 4
		mov edx, [esi]		;y坐标存在edx中
		.if edx > enemyY
			sub edx, enemyY
			.if edx < 20
				.if enemyX > ebx
					;invoke shownum, hWin, enemyY
					mov eax, ebx
					mov ebx, enemyX
					sub ebx, eax
				.else
					sub ebx, enemyX
				.endif
				.if ebx < 30	;该坐标附近有子弹，此子弹消失
					;invoke shownum, hWin, enemyX
					sub esi, 8
					mov eax, 0
					mov [esi], eax
					jmp DETECTOVER3
				.endif
			.endif
		.endif
		add esi, 8
	.else
		add esi, 16
	.endif
	dec ecx
	jne DETECT3
	mov eax, 1
DETECTOVER3:
	pop edx
	pop ebx
	pop esi
	pop ecx
	ret
detectBulletAroundEnemies endp

clearScreen proc hWin:DWORD, stRect:RECT
	pushad
	;清空敌机
	mov esi, offset enemies
	mov ecx, enemyNum
	CLEAR1:
	mov eax, [esi]
	.if eax == 1
		mov eax, 0
		mov [esi], eax
	.endif
	add esi, 24
	LOOP CLEAR1
	;清空子弹
	mov esi, offset bullets
	mov ecx, bulletNum
	CLEAR2:
	mov eax, [esi]
	.if eax == 1
		mov eax, 0
		mov [esi], eax
	.endif
	add esi, 16
	LOOP CLEAR2
	popad
	ret
clearScreen endp

;
drawAllExplodsion PROC graphics:HANDLE, hWin:DWORD
	pushad
	mov ecx, ExplodsionNum
	mov esi, offset Explodsion
	;invoke shownum, hWin, ecx
	
E1:
	mov bx, [esi]
	;invoke shownum, hWin, ebx
	add esi, 2
	mov dx, [esi]
	add esi, 2
	invoke drawIcon, graphics, pngImage,  ebx, edx, explosion_one, hWin
	invoke mciSendString, CTXT("seek small to start"), NULL, 0, 0 ;放完一次指针就会被移到末尾，因此播放前要先移到开头
	invoke mciSendString, CTXT("play small"), NULL, 0, 0			
	;loop E1
 	mov ExplodsionNum, 0
	ret
	popad
drawAllExplodsion endp

gdiplusLoadBitmapFromResource proc hInst:HMODULE, lpName:LPSTR, lpType:LPSTR, pBitmapFromStream:DWORD

	local rcRes:HRSRC
	local hResData:HRSRC
	local pResData:HANDLE
	local sizeOfRes:DWORD
	local hbuffer:HANDLE
	local pbuffer:DWORD
	local pIStream:DWORD
	local hIStream:DWORD

	; ------------------------------------------------------------------
	; STEP 1: Find the resource
	; ------------------------------------------------------------------
	invoke	FindResource, hInst, lpName, lpType
	or 		eax, eax
	jnz		@f
	jmp		gdiplusLoadBitmapFromResource@Close
@@:	mov		rcRes, eax
	
	; ------------------------------------------------------------------
	; STEP 2: Load the resource
	; ------------------------------------------------------------------
	invoke	LoadResource, hInst, rcRes
	or		eax, eax
	jnz		@f
	ret		; Resource was not loaded
@@:	mov		hResData, eax

	; ------------------------------------------------------------------
	; STEP 3: Create a stream to contain our loaded resource
	; ------------------------------------------------------------------
	invoke	SizeofResource, hInst, rcRes
	or		eax, eax
	jnz		@f
	jmp		gdiplusLoadBitmapFromResource@Close
@@:	mov		sizeOfRes, eax
	
	invoke	LockResource, hResData
	or		eax, eax
	jnz	 	@f
	jmp		gdiplusLoadBitmapFromResource@Close
@@:	mov		pResData, eax

	invoke	GlobalAlloc, GMEM_MOVEABLE, sizeOfRes
	or		eax, eax
	jnz		@f
	jmp		gdiplusLoadBitmapFromResource@Close
@@:	mov		hbuffer, eax

	invoke	GlobalLock, hbuffer
	mov		pbuffer, eax
	
	invoke	RtlMoveMemory, pbuffer, hResData, sizeOfRes
	invoke	CreateStreamOnHGlobal, pbuffer, FALSE, addr pIStream
	or		eax, eax
	jz		@f
	jmp		gdiplusLoadBitmapFromResource@Close
@@:	

	; ------------------------------------------------------------------
	; STEP 4: Create an image object from stream
	; ------------------------------------------------------------------
	invoke	GdipCreateBitmapFromStream, pIStream, pBitmapFromStream
	
	; ------------------------------------------------------------------
	; STEP 5: Free all used locks and resources
	; ------------------------------------------------------------------
	invoke	GetHGlobalFromStream, pIStream, addr hIStream
	invoke	GlobalFree, hIStream
	invoke	GlobalUnlock, hbuffer
	invoke	GlobalFree, hbuffer
	
gdiplusLoadBitmapFromResource@Close:
	ret
gdiplusLoadBitmapFromResource endp
	
END START