;MASMPlus ����ģ�� - ��ͨ�� Windows �������

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
;����ɻ�
Hero struct
	x DWORD ?
	y DWORD ?
	status DWORD ?
Hero ends
;�����ӵ�
Bullet struct
	status DWORD ?
	x DWORD ?
	y DWORD ?
	curtype DWORD ?
Bullet ends
;�������
PObject struct
	status DWORD 0;0 dead, 1 active
	x DWORD ?
	y DWORD 0
	speed DWORD 1;initial 1
	hitnum DWORD 0
	curtype DWORD 0;0 small plane, 1 big plane, 2 boss plane, 3 bullet_zero, 4, bullet_one
PObject ends
;����pngͼ���ϸ���Ԫ�ص�λ��
location struct
	x DWORD ?
	y DWORD ?
	w DWORD ?
	h DWORD ?
location ends

	WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
	WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
	;��ʼ����Ϸ����
	initGame proto hWin:DWORD, stRect:RECT
	;����ĳ��icon(x, y)�������꣬locΪ��Ӧ�����location����
	drawIcon proto g:HANDLE, png:DWORD, x:DWORD, y:DWORD, loc:location, :DWORD
	;��ӡĳ������
	shownum proto hWin:DWORD, num:DWORD
	;�����ӵ�
	drawBullets proto hWin:DWORD, stRect:RECT
	;���Ƶл�
	drawEnemies proto hWin:DWORD, stRect:RECT
	;������������
	drawAllObjects proto g:HANDLE, hWin:DWORD, stRect:RECT
	;�л��������ײ���
	detectCollideWithPlayer proto hWin:DWORD, stRect:RECT
	;�л����ӵ�����ײ���
	detectCollideWithBullets proto hWin:DWORD, stRect:RECT
	;����ӵ��͵л�
	clearScreen proto hWin:DWORD, stRect:RECT
.DATA
	szClassName db "MASMPlus_Class",0
	hdc HDC ?
	path BYTE "bg_02.bmp", 0
	pngpath BYTE "plane.png", 0
	btnPngPath BYTE "images/button_bg.png", 0
	pstatus DWORD 0;0��ʾ��ʼ��1��ʾ��ս��2��ʾ����
	pbutton BYTE "button", 0
	pstart BYTE "START", 0
	;��ʼ��gdi+����
	gdiplusToken	dd ?
	gdiplusSInput	GdiplusStartupInput <1, NULL, FALSE, FALSE>
	;pngͼ�������
	pngImage		dd NULL
	btnPngImage dd NULL
	pngType		db "PNG", 0
	bkImage 		dd NULL
	;���ڵ��Ը�ʽ����ӡ����
	;--------------temp data to print
	stri BYTE "%i", 0
	temp BYTE 20 dup(0)
	;------------element id register------------
	startButtonId DWORD 10
	;------------planes-----------------
	Me Hero <>
	enemies PObject 40 dup(<>)
	bullets Bullet 40 dup(<>)
	countBullets DWORD ? ;��ʱ����ÿ8�·�һ���ӵ�
	countSEnemies DWORD ? ;��ʱ����ÿ32
	countMEnemies DWORD ? ;��ʱ����ÿ64
	countBEnemies DWORD ? ;��ʱ����ÿ128
	clientWidth DWORD ? ;��Ļ�ĳ�
	clientHeight DWORD ? ;��Ļ�Ŀ�
	enemyNum DWORD 40 ;�л������������С
	bulletNum DWORD 40;�ӵ������������С 
	;TotalNum DWORD 200;PlaneYou ʹ�õ�����
	
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
		;���ö�ʱ��
		invoke SetTimer, hWin, 1, 30, NULL
		;����ͼ����Դ
		invoke gdiplusLoadBitmapFromResource, hInstance, 2002, addr pngType, addr bkImage
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
;���������¼�
	.elseif uMsg == WM_PAINT
		invoke BeginPaint, hWin, ADDR stPs
		mov eax, stPs.hdc
		mov hdc, eax
		mov eax, stPs.rcPaint.right
	;˫����
		invoke GetClientRect, hWin, ADDR stRect
	
		invoke CreateCompatibleDC, hdc
		mov hdcbuffer, eax
		invoke SaveDC, hWin
		mov nhb, eax
		;initGame֮�����clientWidth��clientHeight��ֵ
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
			invoke drawAllObjects, graphics, hWin, stRect			;���Ƴ��������������
		.elseif pstatus == 2			 ;��Ϸ����
			;��ҷɻ��ı�ըЧ�����ƿ�ʼ
			invoke drawIcon, graphics, pngImage, Me.x, Me.y, explosion_three, hWin
			invoke drawAllObjects, graphics, hWin, stRect			;���Ƴ��������������
			mov eax, clientWidth
			mov ecx, clientHeight
			
			invoke BitBlt, hdc, 0, 0, eax, ecx, hdcbuffer, 0, 0, SRCCOPY

			invoke	GdipDeleteGraphics, graphics
			invoke DeleteObject, pbitmap
			
			invoke DeleteDC, hdcbuffer
			
			invoke EndPaint, hWin, ADDR stPs
			;��ҷɻ��ı�ըЧ���������
			invoke mciSendString, CTXT("close shootmp3"), NULL, 0, 0 ;�ر�����
			invoke KillTimer, hWin, 1;�رռ�ʱ��
			invoke MessageBox, hWin, CTXT("Try Again"), CTXT("Try Again"), MB_YESNO;�Ƿ�����
			cmp eax, 6
			jne    Thankyou
			invoke clearScreen, hWin, stRect ;���ȷ��
			invoke SetTimer, hWin, 1, 30, NULL
        	mov eax, 1
        	mov pstatus, eax
        	invoke initGame, hWin, stRect    
        	ret
    		Thankyou:								;���ȡ��
    			invoke MessageBox, hWin, CTXT("Thank You"), CTXT("Thank You"), MB_OK
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
	;���������¼�
	.elseif uMsg == WM_KEYDOWN
		.if wParam == VK_LEFT
			;���Ե�ж�
			.if Me.x <= 30 
				ret
			.endif
			;�����ƶ�
			sub Me.x, 9
			.if eax == 0
				invoke MessageBox, hWin, CTXT("H"), CTXT("H"), MB_OK
			.endif
		.elseif wParam == VK_RIGHT
			;�ұ�Ե�ж�
			mov eax, clientWidth
			sub eax, 48
			.if Me.x >= eax 
				ret
			.endif
			;�����ƶ�
			add Me.x, 9
			.if eax == 0
				invoke MessageBox, hWin, CTXT("H"), CTXT("H"), MB_OK
			.endif
		.elseif wParam == VK_UP
			;�ϱ�Ե�ж�
			.if Me.y == 38
				ret
			.endif
			;�����ƶ�
			sub Me.y, 6
			.if eax == 0
				invoke MessageBox, hWin, CTXT("H"), CTXT("H"), MB_OK
			.endif
		.elseif wParam == VK_DOWN
			;�±�Ե�ж�
			mov eax, clientHeight
			sub eax, 60
			.if Me.y >= eax
				ret
			.endif
			;�����ƶ�
			add Me.y, 6
			.if eax == 0
				invoke MessageBox, hWin, CTXT("H"), CTXT("H"), MB_OK
			.endif
		.elseif wParam == 13 ;��ENTER����ʼ��Ϸ
			invoke initGame, hWin, stRect
		.endif
	;����ʱ���¼�
	.elseif uMsg == WM_TIMER
		.if pstatus == 1		
			inc countBullets
			inc countSEnemies
			;�����ӵ��͵л�
			invoke drawEnemies, hWin, stRect
			invoke drawBullets, hWin, stRect
			
			;�жϵл����ӵ��Ƿ���ײ������ײ���Ʊ�ըЧ��
			
			;�жϷɻ���л��Ƿ���ײ������ײ���Ʊ�ըЧ��
			invoke detectCollideWithPlayer, hWin, stRect
			
		.endif
		;����ʱ���л���ͼ��
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
	;��������
	invoke mciSendString, CTXT("open shoot.mp3 alias shootmp3 type mpegvideo"), NULL, 0, 0
	invoke mciSendString, CTXT("play shootmp3 repeat"), NULL, 0, 0
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
	mov esi, offset bullets
	mov ebx, SIZEOF Bullet
	mov ecx, bulletNum
	dec ecx
	mov eax, countBullets
	;----ÿ8��ʱ�����ӵ�
	shr eax, 3
	.if eax == 1	
		mov eax, 0
		mov countBullets, eax ;��ʱ������

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
	
	;�ӵ��˶�	
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
		sub eax, 12		;�ӵ��˶��ٶ�
		.if eax < 12
			mov ebx, esi
			sub ebx, 8 
			mov eax, 0
			mov [ebx], eax
		.elseif
			mov [esi], eax
		.endif
		add esi, 8
	.endif
	Loop T1
	
	popad
	ret
drawBullets endp


drawEnemies proc hWin:DWORD, stRect:RECT
	pushad
	mov esi, offset enemies
	mov ebx, SIZEOF PObject
	mov ecx, enemyNum
	dec ecx
	mov eax, countSEnemies
	;----ÿ32ʱ�Ӳ�������
	shr eax, 5
	.if eax == 1
		mov eax, 0
		mov countSEnemies, eax ;��ʱ������
		invoke GetTickCount;�ü�ʱ��ģ�����
		mov ebx, 61 ;����һ����������eax
		imul ebx
		mov ebx, clientWidth	;������Ļ�ĳ���
		sub ebx, 48
		div ebx			;��������edx��
	T2: ;�ҵ���һ������λ�ã�����һ���л�
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
			mov eax, 1 ;�л����ٶ�Ϊ1��������
			mov [esi], eax ; speed
			add esi, 4
			mov eax, 1
			mov [esi], eax ; hitnum����ʾ���ӵ����ж��ٴλᱬը
			add esi, 4
			invoke GetTickCount ;����л�������
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

	;�ƶ����ел�
MOVELABLE2:
	mov esi, offset enemies
	mov ecx, enemyNum
	dec ecx
T3:
	mov eax, [esi]
	
	.if eax == 1
		mov eax, 8
		add esi, eax   ;�ı�л���yֵ
		mov eax, [esi] 
		add eax, 12		;��yֵ��12����ֵ�ɸ��ݷɻ��ٶȲ�ͬ���е�����
		;�жϵл��Ƿ�ɳ�����
		mov edx, clientHeight
		sub edx, 30
		.if eax > edx
			mov ebx, esi
			sub ebx, 8 
			mov eax, 0
			mov [ebx], eax
		.elseif
			mov [esi], eax
		.endif
		add esi, 16		;����һ���ɻ�������
	.endif
	Loop T3
	;invoke GetClientRect, hWin, addr stRect 
	;invoke InvalidateRect, hWin, addr stRect, 0
	;invoke SendMessage, hWin, WM_PAINT, NULL, NULL
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
		.if eax == 1 ;����16�ֽ�
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
		.if eax == 1 ;�л�active������24�ֽ�
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
		.elseif;�л�dead��δ���壬����
			add esi, 24
		.endif
		dec ecx
		jne E1
	popad
	ret
drawAllObjects endp

detectCollideWithPlayer proc hWin:DWORD, stRect:RECT
	;ѭ����ǰ���еĵл�λ�ã��ж��Ƿ���ײ
	pushad
	mov esi, offset enemies
	mov ecx, enemyNum
DETECT1:
	mov eax, [esi]
	.if eax == 1
		add esi, 4
		mov ebx, [esi]
		.if ebx > Me.x		;x�����ֵ
			sub ebx, Me.x
		.else
			mov eax, ebx
			mov ebx, Me.x
			sub ebx, eax
		.endif
		add esi, 4
		.if ebx<50
			mov edx, [esi]		;y�����ֵ
			.if edx > Me.y
				sub edx, Me.y
			.else
				mov eax, edx
				mov edx, Me.y
				sub edx, eax
			.endif
			.if edx < 50		;������ײ
				mov eax,2
				mov pstatus, eax
				invoke mciSendString, CTXT("open explosion.mp3 alias explosionmp3 type mpegvideo"), NULL, 0, 0
				invoke mciSendString, CTXT("play explosionmp3"), NULL, 0, 0
			.endif
		.endif
		add esi, 16			;�����е���һ����
	.else
		add esi, 24
	.endif
	dec ecx
	jne DETECT1
	popad
	ret
detectCollideWithPlayer endp

clearScreen proc hWin:DWORD, stRect:RECT
	pushad
	;��յл�
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
	;����ӵ�
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