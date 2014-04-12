;MASMPlus 代码模板 - 普通的 Windows 程序代码

.386
.Model Flat, StdCall
Option Casemap :None
	include struct.inc
	include data.inc
	WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
	WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
	;初始化游戏界面
	initGame proto hWin:DWORD
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
	detectBulletAroundEnemies proto hWin:DWORD, stRect:RECT, enemyX: DWORD, enemyY: DWORD, enemyType: DWORD
	;清空子弹和敌机
	clearScreen proto hWin:DWORD, stRect:RECT
	;画出分数
	drawScore proto graphics:DWORD, score:DWORD, hWin:DWORD
	;
	drawAllExplodsion proto, graphics:HANDLE, hWin:DWORD
	;判断鼠标时否在矩形内
	JudgePointInRect proto x:DWORD, y:DWORD, rect:location, hWin:DWORD 
	
.DATA
	szClassName db "MASMPlus_Class",0
	hdc HDC ?
	path BYTE "bg_02.bmp", 0
	pngpath BYTE "plane.png", 0
	btnPngPath BYTE "images/button_bg.png", 0
	pstatus DWORD 0;0表示开始，1表示大战，2表示结束
	pbutton BYTE "button", 0
	pstart BYTE "START", 0
	pstarthover DWORD 0
	
	;初始化gdi+对象
	gdiplusToken	dd ?
	gdiplusSInput	GdiplusStartupInput <1, NULL, FALSE, FALSE>
	;png图像的数据
	pngImage		dd NULL
	bigPlane dd ?
	smallPlane dd ?
	bossPlane dd ?
	heroPlane dd ?
	pausePng dd ?
	bulletPng dd ?
	btnPngImage dd NULL
	btnhoverPngImage dd NULL
	airwarPng dd ?
	restartPng dd ?
	restarthoverPng dd ?
	continuePng dd ?
	continuehoverPng dd ?
	exitPng dd ?
	exithoverPng dd ?
	numberPng dd ?
	smallExplosion dd ?
	bigExplosion dd ?
	bossExplosion dd ?
	cameraImage dd ?
	cameraHoverImage dd ?
	

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
	Explodsion ECOORD 40 dup(<>)
	ExplodsionNum DWORD 40
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
	exploNum DWORD 40; 屏幕上爆炸数目的数组大小
	;TotalNum DWORD 200;PlaneYou 使用的数量
	score DWORD 0;
	frameNum DWORD 3
	enemySpeed DWORD 4
	playerHSpeed DWORD 12
	

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
	invoke CreateWindowEx,NULL,ADDR szClassName,CTXT("Air Fighting"),WS_OVERLAPPEDWINDOW,460,20, 360, 700,NULL,NULL,hInst,NULL
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
		;invoke CreateWindowEx, NULL, offset pbutton,CTXT("start"), eax, 180,400, 90, 50,hWin,startButtonId,hInstance,NULL
		;invoke CreateWindow, CTXT("button"), CTXT("start"), , 200, 200, 200, 150, hWin, 1, hInstance, NULL
		;设置定时器
		invoke SetTimer, hWin, 1, 10, NULL
		;加载图像资源
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2002, addr pngType, addr bkImage
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2001, addr pngType, addr pngImage
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2000, addr pngType, addr btnPngImage
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2003, addr pngType, addr bigPlane
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2004, addr pngType, addr smallPlane
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2005, addr pngType, addr bossPlane
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2006, addr pngType, addr heroPlane
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2007, addr pngType, addr pausePng
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2008, addr pngType, addr bulletPng
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2009, addr pngType, addr airwarPng
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2010, addr pngType, addr btnhoverPngImage
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2011, addr pngType, addr restartPng
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2012, addr pngType, addr restarthoverPng
		invoke	gdiplusLoadBitmapFromResource, hInstance, 2013, addr pngType, addr continuePng
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2014, addr pngType, addr continuehoverPng
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2015, addr pngType, addr exitPng
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2016, addr pngType, addr exithoverPng
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2017, addr pngType, addr numberPng
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2018, addr pngType, addr smallExplosion
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2019, addr pngType, addr bigExplosion
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2020, addr pngType, addr bossExplosion
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2021, addr pngType, addr cameraImage
		invoke 	gdiplusLoadBitmapFromResource, hInstance, 2022, addr pngType, addr cameraHoverImage

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
				invoke initGame, hWin
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
	
		;invoke GdipDrawImageI, graphics, bkImage, 0, 0
		;invoke GdipDrawImageI, graphics, btnPngImage, 120, 200
		invoke drawIcon, graphics, bkImage, 0, 0, bk_loc, hWin
		mov eax, bk_loc.y
		sub eax, 1
		.if eax == 0
			mov eax, 1300
		.endif
		mov bk_loc.y, eax
		
		
		
		.if pstatus == 0
			 
			 mov ebx, clientWidth
			 shr ebx, 1
			 mov ecx, clientHeight
			 shr ecx, 1
			 sub ecx, 60
			 sub ebx, 40
			 invoke drawIcon, graphics, airwarPng, ebx, ecx, air_png, hWin
			 ;MOV ESI, ptr stRect
			 add ecx, 140
			 add ebx, 20
			 mov edx, btn_png.w
			 shr edx, 1
			 mov eax, ebx
			 sub eax, edx
			 mov start_loc.x, eax
			 mov camera_loc.x, eax
			
			 mov edx, btn_png.h
			 shr edx, 1
			 mov eax, ecx
			 sub eax, edx
			 mov start_loc.y, eax
			 add eax, 50
			 mov camera_loc.y, eax
			 
			 .if pstarthover == 0
			 	invoke GdipDrawImagePointRectI, graphics, btnPngImage, start_loc.x, start_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			 	invoke GdipDrawImagePointRectI, graphics, cameraImage, camera_loc.x, camera_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			 .elseif pstarthover == 1
			 	invoke GdipDrawImagePointRectI, graphics, btnhoverPngImage, start_loc.x, start_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			 	invoke GdipDrawImagePointRectI, graphics, cameraImage, camera_loc.x, camera_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			 .elseif pstarthover == 2
			 	invoke GdipDrawImagePointRectI, graphics, btnPngImage, start_loc.x, start_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			 	invoke GdipDrawImagePointRectI, graphics, cameraHoverImage, camera_loc.x, camera_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			 .endif
			 
			; invoke drawIcon, graphics, btnPngImage,ebx, ecx, btn_png, hWin
			;mov pstarthover, 0
		
		.elseif pstatus == 1
			invoke drawIcon, graphics, pausePng, 15, 15, pause_png, hWin
			invoke drawIcon, graphics, heroPlane, Me.x, Me.y, hero_plane, hWin
			invoke drawAllObjects, graphics, hWin, stRect			;绘制除玩家外所有物体
			invoke drawAllExplodsion, graphics, hWin
			invoke drawScore, graphics, score, hWin
		.elseif pstatus == 3
			invoke drawIcon, graphics, pausePng, 15, 15, pause_png, hWin
			invoke drawIcon, graphics, heroPlane, Me.x, Me.y, hero_plane, hWin
			invoke drawAllObjects, graphics, hWin, stRect			;绘制除玩家外所有物体
			invoke drawAllExplodsion, graphics, hWin
			
			invoke drawScore, graphics, score, hWin
			
			.if pstarthover !=2
				invoke GdipDrawImagePointRectI, graphics, restartPng, restart_loc.x, restart_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			.elseif pstarthover == 2
				invoke GdipDrawImagePointRectI, graphics, restarthoverPng, restart_loc.x, restart_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			.endif
			.if pstarthover != 4
				invoke GdipDrawImagePointRectI, graphics, continuePng, continue_loc.x, continue_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			.elseif pstarthover == 4
				invoke GdipDrawImagePointRectI, graphics, continuehoverPng, continue_loc.x, continue_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			.endif
			.if pstarthover != 8
				invoke GdipDrawImagePointRectI, graphics, exitPng, exit_loc.x, exit_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			.elseif pstarthover == 8
				invoke GdipDrawImagePointRectI, graphics, exithoverPng, exit_loc.x, exit_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			.endif
		.elseif pstatus == 2			 ;游戏结束
			;玩家飞机的爆炸效果绘制开始
			invoke drawIcon, graphics, pngImage, Me.x, Me.y, explosion_three, hWin
			invoke drawAllObjects, graphics, hWin, stRect			;绘制除玩家外所有物体
			invoke drawAllExplodsion, graphics, hWin
			
			invoke drawScore, graphics, score, hWin
			mov eax, clientWidth
			mov ecx, clientHeight
			
			.if pstarthover !=2
				invoke GdipDrawImagePointRectI, graphics, restartPng, restart_loc.x, restart_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			.elseif pstarthover == 2
				invoke GdipDrawImagePointRectI, graphics, restarthoverPng, restart_loc.x, restart_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			.endif
		
			.if pstarthover != 8
				invoke GdipDrawImagePointRectI, graphics, exitPng, exit_loc.x, exit_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			.elseif pstarthover == 8
				invoke GdipDrawImagePointRectI, graphics, exithoverPng, exit_loc.x, exit_loc.y, btn_png.x, btn_png.y, btn_png.w, btn_png.h, 2
			.endif
			
			
    	
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
		.if pstatus == 1
			.if wParam == VK_LEFT
				;左边缘判断
				.if Me.x <= 30 
					ret
				.endif
				;向左移动
				mov ebx, playerHSpeed
				sub Me.x, ebx
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
				mov ebx, playerHSpeed
				add Me.x, ebx
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
				invoke initGame, hWin
			.endif
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
	.elseif uMsg==WM_LBUTTONDOWN
		.if pstatus == 1
			mov eax, lParam
			shr eax, 16
	
			.if eax < 30
				mov eax, lParam
				and eax, 0000ffffh
				.if eax < 30
					mov eax, 3
					mov pstatus, eax
					;add pstarthover, 0
					;invoke MessageBox, hWin, CTXT("pause"), CTXT("pause"), MB_OK
				.endif
			.endif
		.elseif pstatus == 0
			mov eax, lParam
			and eax, 0000ffffh
			mov ebx, start_loc.w
			add ebx, start_loc.x
			
			.if eax >start_loc.x 
				.if eax < ebx
					mov eax, lParam
					shr eax, 16
					mov ebx, start_loc.y
					add ebx, start_loc.h
					.if eax > start_loc.y
						.if eax < ebx
							invoke initGame, hWin
							mov eax, 1
							mov pstatus, eax
						.elseif eax > camera_loc.y
							mov ebx, camera_loc.y
							add ebx, camera_loc.h
							.if eax < ebx
								;调用摄像头控制程序
								invoke shownum, hWin, 1
							.endif
						.endif
					.endif
				.endif
			.endif
			mov eax, 0
			mov pstarthover, eax
		.elseif pstatus > 1
			mov ebx, lParam
			and ebx, 0000ffffh
			mov ecx, lParam
			shr ecx, 16
			
			invoke JudgePointInRect, ebx, ecx, restart_loc, hWin
			
			.if eax == 1
				invoke clearScreen, hWin, stRect
				mov eax, 0
				mov score, eax
				invoke drawScore, graphics, score, hWin
				invoke initGame, hWin
			.endif
			.if pstatus == 3
				invoke JudgePointInRect, ebx, ecx, continue_loc, hWin
				.if eax == 1
					mov ebx, 1
					mov pstatus, ebx
				.endif
			.endif
			invoke JudgePointInRect, ebx, ecx, exit_loc, hWin
			.if eax == 1
				invoke SendMessage, hWin,WM_SYSCOMMAND, SC_CLOSE, 0
			.endif
	
			
			
			
		.endif
			
			
	.elseif uMsg == WM_MOUSEMOVE
		.if pstatus == 0
			mov eax, lParam
			and eax, 0000ffffh
			mov ebx, start_loc.w
			add ebx, start_loc.x
			
			.if eax >start_loc.x 
				.if eax < ebx
					mov eax, lParam
					shr eax, 16
					mov ebx, start_loc.y
					add ebx, start_loc.h
					.if eax > start_loc.y
						.if eax < ebx
							mov eax, 1
							mov pstarthover, eax
							ret
						.elseif eax > 450
							.if eax < 473
								mov eax, 2
								mov pstarthover, eax
								ret
							.endif
						.endif
					.endif
				.endif
			.endif
			mov eax, 0
			mov pstarthover, eax
		.elseif pstatus > 1
			mov ebx, lParam
			and ebx, 0000ffffh
			mov ecx, lParam
			shr ecx, 16
			
			invoke JudgePointInRect, ebx, ecx, restart_loc, hWin
			
			.if eax == 1
				
				mov edx, 2
				mov pstarthover, edx
			.endif
			
			invoke JudgePointInRect, ebx, ecx, continue_loc, hWin
			.if eax == 1
				
				mov edx, 4
				mov pstarthover, edx
			.endif
			invoke JudgePointInRect, ebx, ecx, exit_loc, hWin
			.if eax == 1
				
				mov edx, 8
				mov pstarthover, edx
			.endif
		.endif
		
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

initGame proc hWin:DWORD
	;播放声音
	invoke mciSendString, CTXT("open explosion.mp3 alias explosionmp3 type mpegvideo"), NULL, 0, 0
	invoke mciSendString, CTXT("open small_plane_killed.wav alias small type mpegvideo"), NULL, 0, 0
	;invoke mciSendString, CTXT("open shoot.mp3 alias shootmp3 type mpegvideo"), NULL, 0, 0
	invoke mciSendString, CTXT("open game.wma alias game type mpegvideo"), NULL, 0, 0
	;invoke mciSendString, CTXT("open fire_bullet.wav alias game1 type mpegvideo"), NULL, 0, 0
	invoke mciSendString, CTXT("play game repeat"), NULL, 0, 0
	;invoke mciSendString, CTXT("play game1 repeat"), NULL, 0, 0
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


	;invoke DestroyWindow, eax
	invoke ShowWindow, eax, SW_HIDE
	mov pstatus, 1
	mov Me.x, 180
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
		mov bl, al	;交换al和ah
		mov al, ah
		mov ah,bl
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
			invoke GetTickCount ;随机敌机的类型
			mov ebx, 7
			div ebx
			.if edx < 4
				mov eax, 1
				mov edx, 0
			.elseif edx < 6
				mov eax, 2
				mov edx, 1
			.else
				mov eax, 4
				mov edx, 2
			.endif
			mov [esi], eax ; hitnum 表示被子弹击中多少次会爆炸
			add esi, 4
			mov [esi], edx ; curtype 表示飞机的类型
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
		add eax, enemySpeed		;将y值加enemySpeed（该值可根据飞机速度不同进行调整）
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
			invoke drawIcon, graphics, bulletPng,  ebx, edx, bullet_png, hWin
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
				invoke drawIcon, graphics, smallPlane,  ebx, edx, small_plane, hWin
			.elseif eax == 1
				invoke drawIcon, graphics, bigPlane,  ebx, edx, big_plane, hWin
			.elseif eax == 2
				invoke drawIcon, graphics, bossPlane,  ebx, edx, boss_plane, hWin
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
	local heroX:DWORD
	local heroY:DWORD
	local enemyX:DWORD
	local enemyY:DWORD
	local flagX:DWORD
	local flag: DWORD
	pushad
	mov esi, offset enemies
	mov ecx, enemyNum
	;依照敌机的不同大小，碰撞范围不同
DETECT1:
	mov eax, [esi]
	.if eax == 1
		;飞机的种类
		mov edi, esi
		add edi, 20
		mov eax, [edi]
		add esi, 4
		mov ebx, [esi]
		add esi, 4
		mov edx, [esi]
		;记录不同飞机的对角坐标
		.if eax == 0
			mov enemyX, ebx
			add enemyX, 5
			add ebx, small_plane.w
			add ebx, 10
			mov enemyY, edx
			add edx, small_plane.h
		.elseif eax == 1
			mov enemyX, ebx
			add ebx, big_plane.w
			add ebx, 10
			mov enemyY, edx
			add edx, big_plane.h
			sub edx, 10
		.elseif eax == 2
			mov enemyX, ebx
			sub enemyX, 20
			add ebx, boss_plane.w
			mov enemyY, edx
			add edx, boss_plane.h
			sub edx, 20
		.endif
		;判断X轴是否碰撞
		mov eax, Me.x
		.if enemyX < eax
			.if Me.x < ebx
				mov eax, 1
			.else
				mov eax, 0
			.endif
			mov flagX, eax
		.else
			add eax, hero_plane.w
			
			.if enemyX < eax
				mov eax, 1
			.else
				mov eax, 0
			.endif
			mov flagX, eax
		.endif
		;判断Y轴是否碰撞
		.if flagX == 1
			mov eax, Me.y
			.if enemyY < eax
				.if Me.y < edx
					mov eax, 1
				.else
					mov eax, 0
				.endif
				mov flag, eax
			.else
				add eax, hero_plane.h
				.if enemyY < eax
					mov eax, 1
				.else
					mov eax, 0					
				.endif
				mov flag, eax
			.endif
		.endif
		;发生碰撞显示效果
		.if flag == 1
			mov eax,2
			mov pstatus, eax
			invoke mciSendString, CTXT("seek explosionmp3 to start"), NULL, 0, 0 ;放完一次指针就会被移到末尾，因此播放前要先移到开头
			invoke mciSendString, CTXT("play explosionmp3"), NULL, 0, 0				
		.endif
		add esi, 16
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
		mov edi, esi 
		add edi, 12
		;判断(x,y)附件有没有子弹，如果有，飞机和子弹都消失，子弹需在飞机前
		invoke detectBulletAroundEnemies, hWin, stRect, ebx, edx, [edi]
		; eax=0表示有子弹， eax=1表示没子弹
		.if eax == 0
			;检测飞机类型，将hitnum--
			mov edi, esi
			add edi, 8
			mov eax, [edi]
			dec eax
			.if eax <= 0
				;飞机消失
				sub esi, 8
				mov [esi], eax
				add esi, 8
				;在飞机消失处(ebx,edx)爆炸
				push edi
				push eax
				mov edi, offset Explodsion
				
EXPLORECORD:
				mov eax, [edi]
				.if eax == 0
					mov eax, frameNum
					mov [edi], eax  ;为了达到肉眼显示要求，每次画n帧
					
					add edi, 4
					mov [edi], ebx
					
					add edi, 4
					mov [edi], edx
					
					add edi, 4
					add esi, 12
					mov eax, [esi]
					mov [edi], eax
					add edi, 4
					.if eax == 0
						mov eax, 100
						add score, eax
					.elseif eax == 1
						mov eax, 200
						add score, eax
					.elseif eax == 2
						mov eax, 400
						add score, eax
					.endif
					jmp RECORDOVER  ;找到一个位置
				.else
					add edi, 16
				.endif	
				dec ExplodsionNum
				jne EXPLORECORD
RECORDOVER:
				mov ExplodsionNum, 40
				pop eax
				pop edi
				add esi, 4
			.else
				mov [edi], eax
				add esi, 16
			.endif		
		.elseif
			add esi, 16
		.endif
	.else
		add esi, 24
	.endif
	dec ecx
	jne DETECT2
	popad
	ret
detectCollideWithBullets endp

detectBulletAroundEnemies proc hWin:DWORD, stRect:RECT, enemyX1: DWORD, enemyY1: DWORD, enemyType: DWORD
	local enemyX2: DWORD
	local enemyY2: DWORD
	push ecx
	push esi
	push ebx
	push edx
	
	;存储x2坐标
	mov eax, enemyX1
	mov ecx, eax
	.if enemyType == 0
		add eax, small_plane.x
		add eax, 30
		.if ecx < 20
			mov ecx, 0 
		.else
			sub ecx, 20
		.endif
	.elseif enemyType == 1
		add eax, big_plane.x
		add eax, 50
		.if ecx < 20
			mov ecx, 0 
		.else
			sub ecx, 20
		.endif
	.elseif enemyType == 2
		add eax, boss_plane.x
		add eax, 85
		.if ecx < 40
			mov ecx, 0
		.else
			sub ecx, 40
		.endif
	.endif
	mov enemyX1, ecx
	mov enemyX2, eax
	;存储x1坐标
	mov eax, enemyY1
	.if enemyType == 0
		add eax, small_plane.y
	.elseif enemyType == 1
		add eax, big_plane.y
	.elseif enemyType == 2
		add eax, boss_plane.y
	.endif
	mov enemyY2, eax

	mov esi, offset bullets
	mov ecx, bulletNum
DETECT3:
	mov eax, [esi]
	.if eax == 1
		add esi, 4
		mov ebx, [esi]		;x坐标存在ebx中
		add esi, 4
		mov edx, [esi]		;y坐标存在edx中
		.if edx > enemyY1
			sub edx, enemyY1
			.if edx < 20
				.if enemyX1 < ebx
					;invoke shownum, hWin, enemyX2
					.if ebx < enemyX2 ;该坐标附近有子弹，此子弹消失
						sub esi, 8
						mov eax, 0
						mov [esi], eax
						jmp DETECTOVER3					
					.endif
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
	mov esi, offset Explodsion
	
AllEX1:
	mov eax, [esi]
	.if eax > 0
		dec eax
		mov [esi], eax
		add esi, 4
		mov ebx, [esi]
		add esi, 4
		mov edx, [esi]
		add esi, 4
		mov eax, [esi]
		add esi, 4
		.if eax == 0
			invoke drawIcon, graphics, smallExplosion,  ebx, edx, small_explosion, hWin
		.elseif eax == 1
			invoke drawIcon, graphics, bigExplosion,  ebx, edx, big_explosion, hWin
		.elseif eax == 2
			invoke drawIcon, graphics, bossExplosion,  ebx, edx, boss_explosion, hWin
		.endif
		invoke mciSendString, CTXT("seek small to start"), NULL, 0, 0 ;mciSendString会改ECX的值
		;invoke shownum, hWin, ecx
		invoke mciSendString, CTXT("play small"), NULL, 0, 0
	.else
		add esi, 16
	.endif
	dec ExplodsionNum
	jne AllEX1
 	mov ExplodsionNum, 40
	ret
	popad
drawAllExplodsion endp

JudgePointInRect proc mx:DWORD, my:DWORD, loc:location, hWin:DWORD
	push ebx
	push edx
	push ecx
	mov eax, 0
	mov edx, mx
	mov ecx, my
	.if edx > loc.x
		mov ebx, loc.w
		add ebx, loc.x
		
		.if edx < ebx
			
			.if ecx > loc.y
				mov ebx, loc.h
				add ebx, loc.y
				.if ecx < ebx
					
					mov eax, 1
				.endif
			.endif
		.endif
	.endif
	pop ecx
	pop edx
	pop ebx
	ret
JudgePointInRect endp	
drawScore proc g:DWORD, num:DWORD, h:DWORD
	local loc:location
	invoke wsprintf, OFFSET temp, OFFSET stri, num
	
	mov esi, offset temp
	mov ebx, 50
	mov ecx, 15
	
L1:
	mov eax, 0
	mov al, [esi]
	.if eax == 0
		ret
	.endif
	sub eax, 48
	
	
	mov edi, 25
	mul edi
	add eax, 5
	mov loc.x, eax
	mov loc.y, 0
	mov loc.w, 15
	mov loc.h, 25
	invoke drawIcon, g, numberPng, ebx, ecx, loc, h
	inc esi
	add ebx, 18
	jmp L1
	ret
drawScore endp
	
	
	
END START