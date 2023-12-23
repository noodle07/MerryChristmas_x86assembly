.386
.model flat, stdcall
option casemap:none
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib

.data
    MadeByText db "(c) 2023 José Barroso", 0 ; texto de autoria
    MsgBoxText db "Feliz Natal", 0           ; texto exibido na janela
    ClassName db "FelizNatalClass", 0        ; Nome da classe da janela
    AppName   db "Feliz Natal em x86 Assembly", 0 ; titulo da aplicacao
    hBrush    dd 0   ; identificador do pincel

.data?
    hInstance HINSTANCE ? ; handle da instancia do programa
    hwnd      HWND      ? ; handle da janela

WINDOW_WIDTH equ 400  ; largura da janela
WINDOW_HEIGHT equ 200 ; altura da janela

.code
; Função para calcular o valor RGB
RGB proc r:BYTE, g:BYTE, b:BYTE
    movzx eax, b
    shl eax, 16
    movzx edx, g
    shl edx, 8
    or  eax, edx
    movzx edx, r
    or  eax, edx
    ret
RGB endp

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    LOCAL wc:WNDCLASSEX ;estrutura de informacoes da classe da janela
    LOCAL msg:MSG ;mensagem recebida pela aplicacao

    ;configuracao da classe da janela
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, OFFSET WndProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    push hInstance
    pop wc.hInstance
    
    ; Cor da janela (RGB)
    invoke RGB, 1, 50, 13 ; Verde cor de natal :P
    invoke CreateSolidBrush, eax
    mov hBrush, eax
    mov [wc.hbrBackground], eax ; Define o pincel como o fundo da janela, então não precisamos do OFFSET

    ;Configuração de icones e cursores
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, OFFSET ClassName
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
    invoke RegisterClassEx, addr wc

    ; criacao da janela
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, OFFSET ClassName, OFFSET AppName, \
           WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, WINDOW_WIDTH, WINDOW_HEIGHT, \
           NULL, NULL, hInst, NULL
    mov hwnd, eax
    invoke ShowWindow, hwnd, CmdShow
    invoke UpdateWindow, hwnd

    ;loop principal da aplicacao
    .WHILE TRUE
        invoke GetMessage, ADDR msg, NULL, 0, 0
        .BREAK .IF (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .ENDW

    ;libertar pincel da memoria
    invoke DeleteObject, hBrush

    mov eax, msg.wParam
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL rect:RECT ;retangulo da area da janela
    LOCAL ps:PAINTSTRUCT  ; estrutura de pintura
    
    .IF uMsg == WM_DESTROY
        ; mensagem de destruicao da janela, encerra a aplicacao
        invoke PostQuitMessage, NULL
        mov eax, 0 ; Valor de retorno
    .ELSEIF uMsg == WM_PAINT
        ; mensagem de pintura da janela
        invoke GetClientRect, hWnd, ADDR rect
        invoke BeginPaint, hWnd, ADDR ps
        mov ebx, ps.hdc ; Usar EBX para preservar EAX, pois invoke pode usa-lo
        invoke SelectObject, ebx, hBrush
        invoke Rectangle, ebx, rect.left, rect.top, rect.right, rect.bottom
        invoke SetBkMode, ebx, TRANSPARENT
        invoke RGB, 255, 0, 0 ;cor rgb branca
        invoke SetTextColor, ebx, eax ; Set text color to white
        invoke DrawText, ebx, OFFSET MsgBoxText, -1, ADDR rect, DT_SINGLELINE or DT_CENTER or DT_VCENTER

        ; adiciona o texto Mady by Jose Barroso
        invoke RGB, 255, 255, 255 ;cor branca
        invoke SetTextColor, ebx, eax
        invoke SetBkMode, ebx, TRANSPARENT
        invoke TextOut, ebx, 10, rect.top , OFFSET MadeByText, SIZEOF MadeByText - 1

        invoke EndPaint, hWnd, ADDR ps
        xor eax, eax ; Return value
    .ELSE
        ;mensagem padrao, delga para o procedimento padrao da janela
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    .ENDIF
    ret
WndProc endp

start:
    ; Obtem a instancia do modulo
    invoke GetModuleHandle, NULL
    mov hInstance, eax
    
    ; Chama a funcao principal da aplicacao
    invoke WinMain, hInstance, NULL, NULL, SW_SHOWNORMAL
    
    ; Encerra a aplicacao
    invoke ExitProcess, eax
end start
