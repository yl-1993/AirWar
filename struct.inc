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
;
ECOORD struct
	remainNum DWORD ?
	x DWORD ?
	y DWORD ?
	curtype DWORD ?
ECOORD ends
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
include gdiplus.asm
