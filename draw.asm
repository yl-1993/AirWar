Include windows.inc
.data
	externdef stri:BYTE
	externdef temp:BYTE
	externdef hdc:HDC
.code
mypaint proc hWin:HANDLE
		local stPs:PAINTSTRUCT
		local stRect:RECT
		local pbitmap:HBITMAP
		local sbitmap:HBITMAP
		local hdcbuffer:HDC
		local graphics:HANDLE
		local pbrush:HBRUSH
		local nhb:DWORD
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
mypaint endp

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
