#include <WinAPIFiles.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>
#include <Array.au3>


Func _ProcessGetPath($vProcess)
	Local $iPID = ProcessExists($vProcess)
	If Not $iPID Then Return SetError(1, 0, -1)

	Local $aProc = DllCall('kernel32.dll', 'hwnd', 'OpenProcess', 'int', BitOR(0x0400, 0x0010), 'int', 0, 'int', $iPID)
	If Not IsArray($aProc) Or Not $aProc[0] Then Return SetError(2, 0, -1)

	Local $vStruct = DllStructCreate('int[1024]')

	Local $hPsapi_Dll = DllOpen('Psapi.dll')
	If $hPsapi_Dll = -1 Then $hPsapi_Dll = DllOpen(@SystemDir & '\Psapi.dll')
	If $hPsapi_Dll = -1 Then $hPsapi_Dll = DllOpen(@WindowsDir & '\Psapi.dll')
	If $hPsapi_Dll = -1 Then Return SetError(3, 0, '')

	DllCall($hPsapi_Dll, 'int', 'EnumProcessModules', _
			'hwnd', $aProc[0], _
			'ptr', DllStructGetPtr($vStruct), _
			'int', DllStructGetSize($vStruct), _
			'int_ptr', 0)
	Local $aRet = DllCall($hPsapi_Dll, 'int', 'GetModuleFileNameEx', _
			'hwnd', $aProc[0], _
			'int', DllStructGetData($vStruct, 1), _
			'str', '', _
			'int', 2048)

	DllClose($hPsapi_Dll)

	If Not IsArray($aRet) Or StringLen($aRet[3]) = 0 Then Return SetError(4, 0, '')
	Return $aRet[3]
EndFunc   ;==>_ProcessGetPath

Func GetDir($sFilePath)
	If Not IsString($sFilePath) Then
		Return SetError(1, 0, -1)
	EndIf

	Local $FileDir = StringRegExpReplace($sFilePath, "\\[^\\]*$", "")

	Return $FileDir
EndFunc   ;==>GetDir

Func GetFilesList($sPath, $sFormat = "*", $fileOnly = 0)
	Local $aFileList = _FileListToArray($sPath, $sFormat, $fileOnly)
	If @error = 1 Or @error = 4 Then
		MsgBox($MB_SYSTEMMODAL, "", "Path was invalid.")
		Exit
	EndIf
	Return $aFileList
EndFunc   ;==>GetFilesList

Func getTelegramDir()
	$telegramDefaultPath = _PathFull("Telegram Desktop", @AppDataDir)
	$telegramProcessPath = GetDir(_ProcessGetPath(ProcessExists("telegram.exe")))

	If ($telegramProcessPath <> -1) Then
		Return $telegramProcessPath
	ElseIf (FileExists($telegramDefaultPath)) Then
		Return $telegramDefaultPath
	Else
		MsgBox(0, 0, "Telegram not found")
		Return 0
	EndIf
EndFunc   ;==>getTelegramDir

Func GetTelegramSessionFiles($telegramPath)
	$tdataFileList = GetFilesList($telegramPath & "\\tdata", Default, 1)

	For $i = 1 To $tdataFileList[0]
		If $tdataFileList[$i] = "working" Then
			_ArrayDelete($tdataFileList, $i)
		EndIf
	Next
	_ArrayDelete($tdataFileList, 0)
;~ _ArrayDisplay($tdataFileList)
	Return $tdataFileList
EndFunc   ;==>GetTelegramSessionFiles

Func GetTelegramSessionFolders($telegramPath)
	$tdataFolderList = GetFilesList($telegramPath & "\\tdata", Default, 2)
	Local $sessionFolders = []

	For $i = 1 To $tdataFolderList[0]
		If StringLen($tdataFolderList[$i]) >= 15 Then
;~ ConsoleWrite($tdataFolderList[$i] & @LF)
			_ArrayAdd($sessionFolders, $tdataFolderList[$i])
		EndIf
	Next
	_ArrayDelete($sessionFolders, 0)
	_ArrayDisplay($sessionFolders)
	Return $sessionFolders
EndFunc   ;==>GetTelegramSessionFolders


GetTelegramSessionFolders(getTelegramDir())
