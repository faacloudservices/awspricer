$local = Get-Location;
$working_directory = ".\awsworkingdirectory";

#Create a Working Directory if it does not exist
# New-Item -Force -Path $working_directory -ItemType directory
# Pull the AWS Price Index
# wget https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json -OutFile awsworkingdirectory\index.json
# Convert to PowerShell Object
# $index = wget https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json
$awsPriceIndex = wget https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json | ConvertFrom-Json
# Access PowerShell Object
# $awsPriceIndex | Get-Member -memberType NoteProperty
#I want to get offers
# $awsPriceIndex.offers
#I want to get EC2

$awsEC2PriceVersionURL = "https://pricing.us-east-1.amazonaws.com" + $awsPriceIndex.offers.AmazonEC2.versionIndexUrl
# $awsEC2PriceURL
$awsEC2PriceVersion = wget $awsEC2PriceVersionURL | ConvertFrom-Json

# Access PowerShell Object
# $awsEC2Price | Get-Member -memberType NoteProperty
# $awsPriceIndex.offers.AmazonEC2.versionIndexUrl
# $awsEC2PriceVersion.currentVersion
# $awsEC2PriceVersion.versions.($awsEC2PriceVersion.currentVersion).offerVersionUrl
# $awsEC2Price.versions.20160126001708 | Get-Member -memberType NoteProperty
# $awsEC2Price.versions.20160126001708.offerVersionUrl
$awsEC2PriceURL = "https://pricing.us-east-1.amazonaws.com" + $awsEC2PriceVersion.versions.($awsEC2PriceVersion.currentVersion).offerVersionUrl
$awsEC2PriceURL
$working_directory
("EC2-"+$awsEC2PriceVersion.currentVersion)
#wget ($awsEC2PriceURL) -OutFile $working_directory\($awsPriceIndex.offers.AmazonEC2.versionIndexUrl).json
$cachePathJson = ".\awsworkingdirectory\EC2-" + ($awsEC2PriceVersion.currentVersion) + ".json"
$cachePathXml = ".\awsworkingdirectory\EC2-" + ($awsEC2PriceVersion.currentVersion) + ".xml"
#$cachePathJson
if ((Test-Path $cachePathXml) -eq $False) {
    if ((Test-Path $cachePathJson) -eq $False) {
        Write-Host "Caching Current EC2 Pricing Information"
        wget ($awsEC2PriceURL) -OutFile $cachePathJson
    } else {
        Write-Host "Converting EC2 Pricing Information to PowerShell Object"
        Get-Content $cachePathJson | ConvertFrom-Json | Export-Clixml $cachePathXml
    }
} else {
    Write-Host "Cache is current"
}
$awsEC2Price = Import-Clixml $cachePathXml

#$awsEC2Price.products.properties

#$awsEC2Price.products | Get-Member | foreach {$_} | select value
#$awsEC2Price.products.properties | Get-Member | foreach {$_} | select value

#This lists the names of the SKUs for EC2
#$awsEC2Price.products | get-member -membertype properties | foreach {$_.Name}

#This lists the number of the SKUs for EC2
#$awsEC2Price.products | get-member -membertype properties | foreach {$_.Name} | Measure-Object

# This lists the definition of each SKU
#$awsEC2Price.products | get-member -membertype properties | foreach {$_.Definition}


#ForEach ($prop in ($awsEC2Price.products | get-member -membertype properties)) {$prop}

#Define a nested array to store the service and pricing data for each sku
$arrayOfGovCloudEc2Skus = @()

ForEach ($prop in ($awsEC2Price.products | get-member -membertype properties)) {
    if ($awsEC2Price.products.($prop.Name).attributes.location -eq "AWS GovCloud (US)") {
        #$arrayOfGovCloudEc2Skus += @($prop.Name, $awsEC2Price.products.($prop.Name).attributes)
        Write-host("Checking AWS Reserved Instance Price list for " + $prop.Name)
        if ($awsEC2Price.terms.Reserved.($prop.Name)) {
            Write-host("Found something for " + $prop.Name)
            Write-host(($awsEC2Price.terms.Reserved.($prop.Name)) | get-member -membertype properties)
            # $offerTermCodesForSku = ($awsEC2Price.terms.Reserved.($prop.Name)) | get-member -membertype properties
            ForEach ($termprop in ($awsEC2Price.terms.Reserved.($prop.Name)) | get-member -membertype properties){
                 Write-host("Doltermprop = " + $termprop)
                 #Write-host("Doltermprop sel exp = " + $termprop | select -exp "offerTermCode")
                 Write-host("Doltermprop Name = " + $termprop.Name )
                 Write-host("Doltermprop offerTermCode = " + $awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).offerTermCode )
                #     Write-host("Doltermprop.offerTermCode = " + $termprop.offerTermCode)
                #     Write-host("Doltermprop.attributes = " + $termprop.attributes)



                if ($awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).termAttributes.LeaseContractLength -eq "1yr" -and $awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).termAttributes.PurchaseOption -eq "All Upfront") {
                    Write-host("Found the 1 year all upfront model for " + $prop.Name)
                    $newObj = New-Object System.Object
                    $newObj | Add-Member -type NoteProperty -name "SKU"                     -value $prop.Name
                    $newObj | Add-Member -type NoteProperty -name Location                  -value $awsEC2Price.products.($prop.Name).attributes.location
                    $newObj | Add-Member -type NoteProperty -name "Tenancy"                 -value $awsEC2Price.products.($prop.Name).attributes.tenancy
                    $newObj | Add-Member -type NoteProperty -name "Instance Type"           -value $awsEC2Price.products.($prop.Name).attributes.instanceType
                    $newObj | Add-Member -type NoteProperty -name "Instance Family"         -value $awsEC2Price.products.($prop.Name).attributes.instanceFamily
                    $newObj | Add-Member -type NoteProperty -name "# virt cores"            -value $awsEC2Price.products.($prop.Name).attributes.vcpu
                    $newObj | Add-Member -type NoteProperty -name "Host CPU"                -value $awsEC2Price.products.($prop.Name).attributes.physicalProcessor
                    $newObj | Add-Member -type NoteProperty -name "Host CPU Clock Speed"    -value $awsEC2Price.products.($prop.Name).attributes.clockSpeed
                    $newObj | Add-Member -type NoteProperty -name "Memory"                  -value $awsEC2Price.products.($prop.Name).attributes.memory
                    $newObj | Add-Member -type NoteProperty -name "OS"                      -value $awsEC2Price.products.($prop.Name).attributes.operatingSystem
                    $newObj | Add-Member -type NoteProperty -name "License"                 -value $awsEC2Price.products.($prop.Name).attributes.licenseModel
                    $newObj | Add-Member -type NoteProperty -name "Bundled SW"              -value $awsEC2Price.products.($prop.Name).attributes.preInstalledSw
                    ForEach ($priceDimension in $awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).priceDimensions | get-member -membertype properties) {
                        # Write-host("price def is " + $awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).($priceDimension.Name).attributes.description)
                        # Write-host("price def is " + $awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).($priceDimension.Name).attributes)
                        # Write-host("price def is " + $awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).($priceDimension.Name).
                        # $priceDimension.Name
                        # Write-host("price def is " + $awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).priceDimensions.($priceDimension.Name).unit)
                        # Write-host("price def is " + $priceDimension.description)
                        # Write-host("price def is " + $priceDimension)
                        if ($awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).priceDimensions.($priceDimension.Name).unit -eq "Quantity") {
                            $perYear = $awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).priceDimensions.($priceDimension.Name).pricePerUnit.USD
                            $perMonth = $perYear / 12;
                            $newObj | Add-Member -type NoteProperty -name "Per Month Cost"                  -value $perMonth
                            # $priceDimension.attributes.pricePerUnit
                            # Write-host("Host of VM is " + $priceDimension.attributes.pricePerUnit.USD)
                        } else {
                            Write-host("derp")
                        }
                    }
                    # $newObj | Add-Member -type NoteProperty -name "Price 1yr upfront"       -value ($awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).priceDimensions | Select-Object -Index 0 )
                    # $newObj | Add-Member -type NoteProperty -name "Experiment"              - Value $awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).priceDimensions[0]
                    $arrayOfGovCloudEc2Skus += $newObj
                #     $arrayOfGovCloudEc2Skus += @(
                #         "SKU":$prop.Name;
                #         "Location":$awsEC2Price.products.($prop.Name).location;
                #         "Instance Type":$awsEC2Price.products.($prop.Name).instanceType;
                #         "Instance Family":$awsEC2Price.products.($prop.Name).instanceFamily;
                #         "# virt cores":$awsEC2Price.products.($prop.Name).vcpu;
                #         "Host CPU":$awsEC2Price.products.($prop.Name).physicalProcessor;
                #         "Host CPU Clock Speed":$awsEC2Price.products.($prop.Name).clockSpeed;
                #         "Memory":$awsEC2Price.products.($prop.Name).memory;
                #         "Price 1yr upfront":$awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).priceDimensions;
                #         "Experiment":$awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name).priceDimensions[0]
                # }
                    # $awsEC2Price.products.($prop.Name).location,



                    # , $awsEC2Price.terms.Reserved.($prop.Name).($termprop.Name))
                }
            }
        } else {
            Write-host("No AWS Reserved Instancee Offer Terms for " + $prop.Name)
        }

        $arrayOfGovCloudEc2Skus | export-csv -path data1.csv




        #Write-host(($awsEC2Price.terms.Reserved.($prop.Name)) | get-member)
        #$offerTermCodesForSku = ($awsEC2Price.terms.Reserved.($prop.Name)) | get-member -membertype properties
        #ForEach ($termprop in $offerTermCodesForSku){
        #   if ($termprop.termAttributes.LeaseContractLength -eq "1yr" -and $termprop.termAttributes.PurchaseOption -eq "All Upfront") {
        #       $arrayOfGovCloudEc2Skus += @($prop.Name, $awsEC2Price.products.($prop.Name).attributes,$termprop)
        #   }
        #}
    }
}
#$awsEC2Price.terms.Reserved.($prop.Name)

$arrayOfGovCloudEc2Skus
$arrayOfGovCloudEc2Skus | Measure-Object

#Sanity Check to make sure that we're accessing the AWS API properly
$awsEC2Price.products.QWQYA39QABGHWZT5.sku
$awsEC2Price.products.QWQYA39QABGHWZT5.productFamily
$awsEC2Price.products.QWQYA39QABGHWZT5.attributes
$awsEC2Price.products.QWQYA39QABGHWZT5.attributes.location
#$awsEC2Price.terms.Reserved
$awsEC2Price.terms.Reserved.DQ578CGN99KG6ECF
$awsEC2Price.terms.Reserved.DQ578CGN99KG6ECF."DQ578CGN99KG6ECF.HU7G6KETJZ"
$awsEC2Price.terms.Reserved.DQ578CGN99KG6ECF."DQ578CGN99KG6ECF.HU7G6KETJZ".offerTermCode
$awsEC2Price.terms.Reserved."DQ578CGN99KG6ECF"."DQ578CGN99KG6ECF.6QCMYABX3D".priceDimensions."DQ578CGN99KG6ECF.6QCMYABX3D.6YS6EN2CT7".unit
$awsEC2Price.terms.Reserved."DQ578CGN99KG6ECF"."DQ578CGN99KG6ECF.6QCMYABX3D".priceDimensions."DQ578CGN99KG6ECF.6QCMYABX3D.6YS6EN2CT7".pricePerUnit.USD
#$awsEC2Price.terms.Reserved.QWQYA39QABGHWZT5."QWQYA39QABGHWZT5.JRTCKXETXF"
#$awsEC2Price.terms.Reserved.QWQYA39QABGHWZT5."QWQYA39QABGHWZT5.JRTCKXETXF".attributes.offerTermCode

#$awsEC2Price.terms.Reserved


#    "termAttributes" : {
#            "LeaseContractLength" : "1yr",
#            "PurchaseOption" : "All Upfront"
#          }

# $awsEC2Price.products | get-member | foreach {$_Definition}
#foreach($prop in $awsEC2Price.products.properties)

# | ? {$_.sku.StartsWith("Q")} | select value)

#$awsEC2Price.GetType()
#$awsEC2Price.products.GetType()
#$awsEC2Price.products | foreach { $_ } | Measure-Object
#$awsEC2Price.products | foreach { $_.psobject }
#$awsEC2Price.products | Get-Member
#$awsEC2Price.products | Where-Object {$_.sku -eq "QWQYA39QABGHWZT5"}
#$awsEC2Price.products.QWQYA39QABGHWZT5
#$awsEC2Price.products.QWQYA39QABGHWZT5.terms
#$awsEC2Price.products.QWQYA39QABGHWZT5 | Get-Member

###Iterate through the EC2 SKUs and add the SKU as a string to an array of strings when the SKU has a location attribute of "AWS GovCloud (US)"
###Iterate through terms onDemand,
###



#$i = 1
#Foreach ($ec2Service in $awsEC2Price.products.attributes) {
#    Write-Host $i
#    $i++
#    $ec2Service.GetItem("sku")
#     if ($ec2Service.attributes.location -eq "AWS GovCloud (US)") {
#         Write-Host "Is in GovCloud"
#     } else {
#         Write-Host "Is not in GovCloud"
#     }

#}

#start $awsEC2PriceURL

# Iterate through JSON and select attributes.location = "AWS GovCloud (US)"
#"location" : "AWS GovCloud (US)",
    # "QWQYA39QABGHWZT5" : {
    #   "sku" : "QWQYA39QABGHWZT5",
    #   "productFamily" : "Compute Instance",
    #   "attributes" : {
    #     "servicecode" : "AmazonEC2",
    #     "location" : "AWS GovCloud (US)",
    #     "locationType" : "AWS Region",
    #     "instanceType" : "i2.4xlarge",
    #     "currentGeneration" : "Yes",
    #     "instanceFamily" : "Storage optimized",
    #     "vcpu" : "16",
    #     "physicalProcessor" : "Intel Xeon E5-2670 v2 (Ivy Bridge)",
    #     "clockSpeed" : "2.5 GHz",
    #     "memory" : "122 GiB",
    #     "storage" : "4 x 800 SSD",
    #     "networkPerformance" : "High",
    #     "processorArchitecture" : "64-bit",
    #     "tenancy" : "Shared",
    #     "operatingSystem" : "Windows",
    #     "licenseModel" : "Bring your own license",
    #     "usagetype" : "UGW1-BoxUsage:i2.4xlarge",
    #     "operation" : "RunInstances:0800",
    #     "enhancedNetworkingSupported" : "Yes",
    #     "preInstalledSw" : "NA",
    #     "processorFeatures" : "Intel AVX; Intel Turbo"
    #   }