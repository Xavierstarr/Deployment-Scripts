# This script is intended to run either as a platform or remediation script in Intune.
# As Hardening may already occur that can stop the CyberCNS Install we need to check that setting via registry, store the existing setting to temporarily revert the config to run the install.

#     Created By:    Justin Eley
#     Date Created:  1/08/2023
#     Date Updated:  1/08/2023

# this could be transferable between clients if you update company variables below:

    #Adjust these variables as needed
    $CompanyID = "COMPANY ID HERE"
    $ClientID = "CLIENT ID HERE"
    $ClientSecret = "CLIENT SECRET HERE"

    #Update the below to "probe" "scan" or "lightweight" depending on desired install
    $installtype = "lightweight"

    # Variables do not change
    $Domain = "YOUR CYBERCNS DOMAIN URL HERE"
    $env = "CYBERCNS DOMAIN NAME HERE"
    $datetime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

# Check and store registry for CMD Hardening, as this needs to be disabled for installation then reverted back
$regCHK = Test-Path "HKCU:\Software\Policies\Microsoft\Windows\System\DisableCMD"

#Check if already installed
$InstallCHK = Get-Item "C:\Program Files (x86)\CyberCNSAgentV2\cybercnsagentmonitor.exe"


if ($InstallCHK) {
    $message = "CyberCNS Already Installed"
    Write-Host $message -ForegroundColor Green
    } Else {
    $message = "Agent not found, proceeding with install"
    Write-Host $message -ForegroundColor Red
            
            if ($regCHK) {
                # Obtain current Command Prompt Policy Setting
                    Try{
                    $initialRegistryValue = Get-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\System" -Name DisableCMD
                    }catch {
                        $message = "Error collecting command prompt policy setting - $($_.Exception.Message)"
                        Write-Host $message -ForegroundColor Red
                        }
                     # Temporarily disable the Command Prompt restriction
                    Try{
                    Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\System" -Name DisableCMD -Value 0
                    $message = "Successfully bypassed CMD Prompt Restriction for CyberCNS Installation $datetime"
                    Write-Host $message -ForegroundColor Green
                    } catch {
                        $message = "Error bypassing command prompt policy temporarily - $($_.Exception.Message)"
                        Write-Host $message -ForegroundColor Red
                    }
                } else {
                Write-Host "CMD Hardening not found, no action needed" -ForegroundColor Yellow
                }

            # Install the CyberCNS vulnerability scanner here (e.g., using an installer or package manager)
            Try{
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; 
             $source = (Invoke-RestMethod -Method "Get" -URI "https://configuration.mycybercns.com/api/v3/configuration/agentlink?ostype=windows");
            $destination = 'cybercnsagent.exe';
            Invoke-WebRequest -Uri $source -OutFile $destination;

             ./cybercnsagent.exe -c $CompanyID -a $ClientID -s $ClientSecret -b $Domain -e $env -i $installtype;

             } catch {
             $message = "Error installing CyberCNS - $($_.Exception.Message)"
            Write-Host $message -ForegroundColor Red
            }

            Start-Sleep -Seconds 60

            if ($regCHK) {
                # Revert Command Prompt Policy back to captured setting
                try{
                Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\System" -Name DisableCMD -Value $initialRegistryValue.DisableCMD
                $message = "Successfully reset command prompt policy back to original setting $datetime"
                Write-Host $message -ForegroundColor Green
                } catch {
                $message = "Error reverting commandprompt policy back to original setting - $($_.Exception.Message)"
                Write-Host $message -ForegroundColor Red
            } Else {
                $message = "Hardening Policy for Command prompt not found, no reverting required"
                write-host = $message -ForegroundColor Green
                }
            }
}