Param(
    $TvShowDir = "C:\temp\Shows",
    $MovieDir = "C:\temp\Movies",
    $TvShowSize = 1GB,
    $MovieSize = 2GB,
    $Format = "mp4",
    $Program = "ffmpeg",
	$Logging = "Console" #Console,PerFile,SingleLog  Console drops all info to console window, perfile creates a new log for each file, singlefile will create a new file for each day.
)
# Specify directory for handbreak and ffmpeg
$HandBreakDir = "C:\Users\$env:USERNAME\Downloads\HandBrakeCLI-1.3.2-win-x86_64"
$ffmpegBinDir = "C:\Users\$env:USERNAME\Downloads\ffmpeg\bin"

# Set the conversion string we want to use for both programs
if($Program -eq "handbreak"){	
	# Handbreak options, add or remove if you don't like them.  Full list: https://handbrake.fr/docs/en/latest/cli/command-line-reference.html
	$Executable = "HandBrakeCLI.exe" #Program executalbe file name.
	$ExecutableDir = $HandBreakDir
	$HandbreakOptions = @()
	$HandbreakOptions += "-f" #Format flag
	$HandbreakOptions += $Format #Format value (MKV or MP4 specified earlier)
	$HandbreakOptions += "-a" #Audio channel flag
	$HandbreakOptions += "1,2,3,4,5,6,7,8,9,10" #Audio channels to scan
	$HandbreakOptions += "-e" #Output video codec flag
	$HandbreakOptions += "x264" #Output using x264
	$HandbreakOptions += "--encoder-preset" #Encode speed preset flag
	$HandbreakOptions += "slow" #Encode speed preset
	$HandbreakOptions += "--encoder-profile" #Encode quality preset flag
	$HandbreakOptions += "high" #Encode quality preset
	$HandbreakOptions += "--encoder-level" #Profile version to use for encoding flag
	$HandbreakOptions += "4.1" #Encode profile value
	$HandbreakOptions += "-q" #CFR flag
	$HandbreakOptions += "27" #CFR value (Higher is less quality)
	$HandbreakOptions += "-E" #Audio codec flag
	$HandbreakOptions += "aac" #Specify AAC to use as the audio codec
	$HandbreakOptions += "--audio-copy-mask" #Permitted audio codecs for copying flag
	$HandbreakOptions += "aac" #Set only AAC as allowed for copying
	$HandbreakOptions += "--verbose=1" #Logging level
	$HandbreakOptions += "--decomb" #Deinterlace video flag
	$HandbreakOptions += "--loose-anamorphic" #Try and keep source aspect ratio
	$HandbreakOptions += "--modulus" #Modulus flag
	$HandbreakOptions += "2" #Modulus value
}
if($Program -eq "ffmpeg"){
	$Executable = "ffmpeg.exe" #Program executalbe file name.
	$ExecutableDir = $ffmpegBinDir
	# ffmpeg options, add or remove if you don'y like them.  Full list: https://ffmpeg.org/ffmpeg.html#Options
	$ffmpegOptions = @()
	#$ffmpegOptions += "-map_metadata" #Map metadata flag
	#$ffmpegOptions += "-1" #Clear all file meta data
	$ffmpegOptions += "-c:v" #Video codec flag
	$ffmpegOptions += "libx264" #Specify x264 as the codec
	$ffmpegOptions += "-preset" #Preset flag
	$ffmpegOptions += "fast" #Use fast preset
	$ffmpegOptions += "-crf" #CRF flag
	$ffmpegOptions += "27" #CRF value (Higher is less quality)
	$ffmpegOptions += "-c:a" #Audio codec flag
	$ffmpegOptions += "aac" #Specify aac for audio codec
}

# Create Variable for storing the current directory
if (!$WorkingDir){
    $WorkingDir = (Resolve-Path .\).Path
}
# Create the Conversion Completed Spreadsheet if it does not exist
$ConversionCSV = "$WorkingDir\ConversionsCompleted.csv"
If(-not(Test-Path $ConversionCSV)){
    $headers = "File Name", "Completed Date"
    $psObject = New-Object psobject
    foreach($header in $headers){
        Add-Member -InputObject $psobject -MemberType noteproperty -Name $header -Value ""
    }
    $psObject | Export-Csv $ConversionCSV -NoTypeInformation
    $ConversionCSV = Resolve-Path -Path $ConversionCSV
}

# Check to see if the exacuteable exists
if(-not(Test-Path("$ExecutableDir\$exacuteable"))){
    Write-Host "$exacuteable not found in $ExecutableDir Please make sure that $programs is installed.  Quitting" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

# Check to see if $MovieDir exists
if(-not(Test-Path("$MovieDir"))){
    Write-Host "Movie directory: $MovieDir not found.  Please make sure the path is correct.  Quitting" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

# Check to see if $TvShowDir exists
if(-not(Test-Path("$TvShowDir"))){
    Write-Host "Tv Show directory: $TvShowDir not found.  Please make sure the path is correct.  Quitting" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

#Create Hash table to check against before starting conversions.  This will prevent converting items that have already been converted (This spreadsheet updates automatically)
$CompletedTable = Import-Csv -Path $ConversionCSV
$HashTable=@{}
foreach($file in $CompletedTable){
    $HashTable[$file."File Name"]=$file."Completed Date"
}

# Output that we are finding file
Write-Host "Finding Movie files over $($MovieSize/1GB)GB in $MovieDir and Episodes over $($TvShowSize/1GB)GB in $TvShowDir be patient..." -ForegroundColor Gray

# Set variables so we can get number of files while scanning
$b = 0
$i = 0

# Get all items in both folders that are greater than the specified size and sort them largest to smallest
$LargeTVEpisodes = Get-ChildItem -Path $TvShowDir -Recurse -File | Where-Object {$_.Length -gt $TvShowSize} | ForEach-Object {$b++; If ($b -eq 1){Write-Host -NoNewLine "`rFound $b file so far..."} Else{Write-Host -NoNewLine "`rFound $b files so far..." -foregroundcolor green};$_}
$LargeMovies = Get-ChildItem -Path $MovieDir -Recurse -File | Where-Object {$_.Length -gt $MovieSize} | ForEach-Object {$b++; If ($b -eq 1){Write-Host -NoNewLine "`rFound $b file so far..."} Else{Write-Host -NoNewLine "`rFound $b files so far..." -foregroundcolor green};$_}
$LargeFiles = $LargeTVEpisodes + $LargeMovies | Sort-Object Length -Descending

# If no large files are found then write that out
If($LargeFiles -eq $null){
    Write-Host "No files over $($MovieSize/1GB)GB in $MovieDir and no Episodes over $($TvShowSize/1GB)GB in $TvShowDir found.  Exiting"
    exit
}

# Get total file count so we can display progress
$num = $LargeFiles | measure
$fileCount = $num.count


# Convert the file using -NEW at the end
foreach($File in $LargeFiles){
	# Incriment $i so we can update progress
	$i++;
	
	# Build the name of the file as we want it to be after the conversion and rename
	$FinalName = "$($File.Directory)\$($File.BaseName).$Format"
    	# Check the Hash table we created from the Conversions Completed spreadsheet.  If it exists skip that file
    	if(-not($HashTable.ContainsKey("$FinalName"))){
		# File name + "-NEW.$Format" we want it to be an $FileFormat file and we don't want to overwrite the file we are reading from if it is already a .$FileFormat
		$OutputFile = "$($File.Directory)\$($File.BaseName)-NEW.$Format"
		
		# Check that the Output file does not already exist, if it does delete it so the new conversions works as intended.
        if(Test-Path $OutputFile){
            Remove-Item $OutputFile -Force
        }

        # Change the CPU priorety of $Executable to below Normal in 10 seconds so that the conversion has started
        Start-Job -ScriptBlock {
            Start-Sleep -s 10
            $p = Get-Process -Name $Executable
            $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
        } | Out-Null
		#region Logging
		if($Logging -ne "Console") {
			# Create the Logs directory if it does not exist
			$LogFileDir = "$WorkingDir\Logs"
			if(!(Test-Path($LogFileDir))){
				New-Item -ItemType Directory -Force -Path $LogFileDir | Out-Null
			}
        }
		If($Logging -eq "PerFile"){
			# Build Log file name
			$LogFileName = $File.BaseName -replace '[[\]]',''
            $LogPath = "$LogFileDir\$LogFileName.txt"
			if($Program -eq "ffmpeg"){
				$ffmpegOptions += "-nostats" #Specify not to send stats to the log file (Logs will get huge without this but you can comment out for testing)
			}
		}
		If($Logging -eq "SingleLog"){
			# Get date info
			$Date = Get-Date
			if(!(Test-Path -path "$LogFileDir\$($Date.Year)\$($Date.Month)\$($Date.Day)")){
				New-Item -path "$LogFileDir\$($Date.Year)\$($Date.Month)\$($Date.Day)" -type Directory | Out-Null
			}
			# Build Log file name
			$LogFileName = "Conversions"
			$LogPath = "$LogFileDir\$($Date.Year)\$($Date.Month)\$($Date.Day)\$LogFileName.txt"
			if($Program -eq "ffmpeg"){
				$ffmpegOptions += "-nostats" #Specify not to send stats to the log file (Logs will get huge without this but you can comment out for testing)
			}
		}
		#endregion
		
		# Input file
		$InputFile = $File.FullName
		
		# Write that we are starting the conversion
		Write-Host "File $i of $fileCount - Total queue $progress%"
        $StartingFileSize = $File.Length/1GB
        Write-Host "Starting conversion on $InputFile it is $([math]::Round($StartingFileSize,2))GB in size before conversion" -ForegroundColor Cyan
		
		if($Program -eq "HandBreak"){
			if($Logging -eq "Console"){
				& $HandBreakDir\HandBrakeCLI.exe -i "$InputFile" -o "$OutputFile" $HandbreakOptions
			}
			else{
				& $HandBreakDir\HandBrakeCLI.exe -i "$InputFile" -o "$OutputFile" $HandbreakOptions 2> $LogPath
			}
		}
		if($Program -eq "ffmpeg"){
			if($Logging -eq "Console"){
				& $ffmpegBinDir\ffmpeg.exe -i "$InputFile" $ffmpegOptions "$OutputFile"
			}
			else{
				& $ffmpegBinDir\ffmpeg.exe -i "$InputFile" $ffmpegOptions "$OutputFile" 2> $LogPath
			}
		}
		# Check to make sure that the output file actuall exists so that if there was a conversion error we don't delete the original
        if($Error.Count -eq 0){
			if(Test-Path $OutputFile){
				Remove-Item $InputFile -Force
				Rename-Item $OutputFile $FinalName
				Write-Host "Finished converting $FinalName" -ForegroundColor Green
				$EndingFile = Get-Item $FinalName | Select-Object Length
				$EndingFileSize = $EndingFile.Length/1GB
				$progress = ($i / $fileCount) * 100
				$progress = [Math]::Round($progress,2)
				Write-Host "Ending file size is $([math]::Round($EndingFileSize,2))GB so, space saved is $([math]::Round($StartingFileSize-$EndingFileSize,2))GB" -ForegroundColor Green
				# Add the completed file to the completed csv file so we don't convert it again later
				$csvFileName = "$FinalName"
				$csvCompletedDate = Get-Date -UFormat "%x - %I:%M %p"
				$hash = @{
					"File Name" =  $csvFileName
					"Completed Date" = $csvCompletedDate
				}
				$newRow = New-Object PsObject -Property $hash
				Export-Csv $ConversionCSV -inputobject $newrow -append -Force
			}
		}
        # If file not found write that the conversion failed.
        elseif ((!(Test-Path $OutputFile)) -Or ($Error.Count -gt 0)){
			$Error.Clear()
            Write-Host "Failed to convert $InputFile" -ForegroundColor Red
        }
	}
	
    # If file exists in Conversions Completed Spreadsheet write that we are skipping the file because it was already converted
    elseif($HashTable.ContainsKey("$FinalName")){
        $CompletedTime = $HashTable.Item("$Finalname")
        Write-Host "Skipping $FinalName because it was already converted on $CompletedTime." -ForegroundColor DarkGreen
    }
}
