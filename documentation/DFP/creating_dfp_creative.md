## Creating a DFP Creative to be served in Sharethrough SDK
#####In the DFP Line Item you would like the creative to serve to
1. Select *Add Creative* 
![Add Creative][add-creative]
2. Select *SDK Mediation* ![SDK Mediation][sdk-mediation]
3. For *Ad Network* select `Custom Event`
4. For *Parameter* enter the `Creative Key` provided by Sharethough
5. For *Label* enter `Sharethrough`
6. For *Class Name* enter `STRDFPMediator` ![New Creative][new-creative]
7. Fill in *Name* and any other fields required by DFP

###It is very important that label be set to Sharethrough and Class Name is set to STRDFPMediator


[add-creative]: AddCreativeSS.png
[sdk-mediation]: SDKMediationSS.png
[inventory-ss]: InventorySS.png
[new-creative]: NewCreativeParams.png