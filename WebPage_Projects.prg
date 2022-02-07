#include "DataWharf.ch"
memvar oFcgi

#include "dbinfo.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageProjects()
local l_cHtml := []
local l_cHtmlUnderHeader

local l_oDB1
local l_oData

local l_cFormName
local l_cActionOnSubmit

local l_iProjectPk
local l_cProjectName
local l_cProjectDescription

local l_hValues := {=>}

local l_cProjectElement := "SETTINGS"  //Default Element

local l_aSQLResult := {}

local l_cURLAction          := "ListProjects"
local l_cURLProjectLinkUID := ""
local l_cURLVersionCode     := ""

local l_cSitePath := oFcgi:RequestSettings["SitePath"]

local l_nAccessLevelML := 1   // None by default
// As per the info in Schema.txt
//     1 - None
//     2 - Read Only
//     3 - Edit Description and Information Entries
//     4 - Edit Description and Information Entries and Diagrams
//     5 - Edit Anything
//     7 - Full Access


oFcgi:TraceAdd("BuildPageProjects")

// Variables
// l_cURLAction
// l_cURLProjectLinkUID
// l_cURLVersionCode

//Improved and new way:
// Projects/                      Same as Projects/ListProjects/
// Projects/NewProject/
// Projects/ProjectSettings/<ProjectLinkUID>/

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]

    if len(oFcgi:p_URLPathElements) >= 3 .and. !empty(oFcgi:p_URLPathElements[3])
        l_cURLProjectLinkUID := oFcgi:p_URLPathElements[3]
    endif

    do case
    case vfp_Inlist(l_cURLAction,"ProjectSettings")
        l_cProjectElement := "SETTINGS"

    otherwise
        l_cProjectElement := "SETTINGS"

    endcase

    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if !empty(l_cURLProjectLinkUID)
        with object l_oDB1
            :Table("95246374-84bd-44a0-877f-c4bc6baca44a","Project")
            :Column("Project.pk"          , "pk")
            :Column("Project.Name"        , "Project_Name")
            :Where("Project.LinkUID = ^" ,l_cURLProjectLinkUID)
            :SQL(@l_aSQLResult)
        endwith

        if l_oDB1:Tally == 1
            l_iProjectPk          := l_aSQLResult[1,1]
            l_cProjectName        := l_aSQLResult[1,2]
        else
            l_iProjectPk   := -1
            l_cProjectName := "Unknown"
        endif
    endif

    do case
    case oFcgi:p_nUserAccessMode <= 1  // Project access levels
        with object l_oDB1
            :Table("143efed2-f4dc-41b9-9543-cf2a52fb1194","UserAccessProject")
            :Column("UserAccessProject.AccessLevelML" , "AccessLevelML")
            :Where("UserAccessProject.fk_User = ^"    , oFcgi:p_iUserPk)
            :Where("UserAccessProject.fk_Project = ^" ,l_iProjectPk)
            :SQL(@l_aSQLResult)
            if l_oDB1:Tally == 1
                l_nAccessLevelML := l_aSQLResult[1,1]
            else
                l_nAccessLevelML := 0
            endif
        endwith

    case oFcgi:p_nUserAccessMode  = 2  // All Project Read Only
        l_nAccessLevelML := 2
    case oFcgi:p_nUserAccessMode  = 3  // All Project Full Access
        l_nAccessLevelML := 7
    case oFcgi:p_nUserAccessMode  = 4  // Root Admin (User Control)
        l_nAccessLevelML := 7
    endcase

else
    l_cURLAction := "ListProjects"
endif

oFcgi:p_nAccessLevelML := l_nAccessLevelML

do case
case l_cURLAction == "ListProjects"
    // l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    //     l_cHtml += [<div class="input-group">]
    //         l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[Projects/">Projects</a>]
    //         if oFcgi:p_nUserAccessMode >= 3
    //             l_cHtml += [<a class="btn btn-primary rounded" ms-0 href="]+l_cSitePath+[Projects/NewProject">New Project</a>]
    //         endif
    //     l_cHtml += [</div>]
    // l_cHtml += [</nav>]

    l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
    l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Projects</span></div>]
    if oFcgi:p_nUserAccessMode >= 3
        l_cHtml += [<div class="px-3 py-2 align-middle"><a class="btn btn-primary rounded align-middle" href="]+l_cSitePath+[Projects/NewProject">New Project</a></div>]
    endif
    l_cHtml += [</div>]


    l_cHtml += ProjectListFormBuild()

case l_cURLAction == "NewProject"
    if oFcgi:p_nUserAccessMode >= 3
        // l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        //     l_cHtml += [<div class="input-group">]
        //         l_cHtml += [<span class="navbar-brand text-white ms-3">New Project</span>]
        //     l_cHtml += [</div>]
        // l_cHtml += [</nav>]

        l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
        l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">New Project</span></div>]
        l_cHtml += [</div>]

        if oFcgi:isGet()
            //Brand new request of add an application.
            l_cHtml += ProjectEditFormBuild("",0,{=>})
        else
            l_cHtml += ProjectEditFormOnSubmit("")
        endif
    endif

case l_cURLAction == "ProjectSettings"
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += ProjectHeaderBuild(l_iProjectPk,l_cProjectName,l_cProjectElement,l_cSitePath,l_cURLProjectLinkUID,.f.)
        
        if oFcgi:isGet()
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("a11b7e98-4717-40e1-8c81-451656153c5a","public.Project")
                :Column("Project.UseStatus"                    , "Project_UseStatus")
                :Column("Project.Description"                  , "Project_Description")
                :Column("Project.AlternateNameForModel"        , "Project_AlternateNameForModel")
                :Column("Project.AlternateNameForModels"       , "Project_AlternateNameForModels")
                :Column("Project.AlternateNameForEntity"       , "Project_AlternateNameForEntity")
                :Column("Project.AlternateNameForEntities"     , "Project_AlternateNameForEntities")
                :Column("Project.AlternateNameForAssociation"  , "Project_AlternateNameForAssociation")
                :Column("Project.AlternateNameForAssociations" , "Project_AlternateNameForAssociations")
                :Column("Project.AlternateNameForAttribute"    , "Project_AlternateNameForAttribute")
                :Column("Project.AlternateNameForAttributes"   , "Project_AlternateNameForAttributes")
                :Column("Project.AlternateNameForDataType"     , "Project_AlternateNameForDataType")
                :Column("Project.AlternateNameForDataTypes"    , "Project_AlternateNameForDataTypes")
                :Column("Project.AlternateNameForPackage"      , "Project_AlternateNameForPackage")
                :Column("Project.AlternateNameForPackages"     , "Project_AlternateNameForPackages")
                l_oData := :Get(l_iProjectPk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["Name"]                         := l_cProjectName
                l_hValues["UseStatus"]                    := l_oData:Project_UseStatus
                l_hValues["Description"]                  := l_oData:Project_Description
                l_hValues["AlternateNameForModel"]        := l_oData:Project_AlternateNameForModel
                l_hValues["AlternateNameForModels"]       := l_oData:Project_AlternateNameForModels
                l_hValues["AlternateNameForEntity"]       := l_oData:Project_AlternateNameForEntity
                l_hValues["AlternateNameForEntities"]     := l_oData:Project_AlternateNameForEntities
                l_hValues["AlternateNameForAssociation"]  := l_oData:Project_AlternateNameForAssociation
                l_hValues["AlternateNameForAssociations"] := l_oData:Project_AlternateNameForAssociations
                l_hValues["AlternateNameForAttribute"]    := l_oData:Project_AlternateNameForAttribute
                l_hValues["AlternateNameForAttributes"]   := l_oData:Project_AlternateNameForAttributes
                l_hValues["AlternateNameForDataType"]     := l_oData:Project_AlternateNameForDataType
                l_hValues["AlternateNameForDataTypes"]    := l_oData:Project_AlternateNameForDataTypes
                l_hValues["AlternateNameForPackage"]      := l_oData:Project_AlternateNameForPackage
                l_hValues["AlternateNameForPackages"]     := l_oData:Project_AlternateNameForPackages

                CustomFieldsLoad(l_iProjectPk,USEDON_PROJECT,l_iProjectPk,@l_hValues)

                l_cHtml += ProjectEditFormBuild("",l_iProjectPk,l_hValues)
            endif
        else
            if l_iProjectPk > 0
                l_cHtml += ProjectEditFormOnSubmit(l_cURLProjectLinkUID)
            endif
        endif
    endif

otherwise

endcase

return l_cHtml
//=================================================================================================================
static function ProjectHeaderBuild(par_iProjectPk,par_cProjectName,par_cProjectElement,par_cSitePath,par_cURLProjectLinkUID,par_lActiveHeader)
local l_cHtml := ""
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_iReccount
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
 
oFcgi:TraceAdd("ProjectHeaderBuild")

// l_cHtml += [<nav class="navbar navbar-default bg-secondary bg-gradient">]
//     l_cHtml += [<div class="input-group">]
//         l_cHtml += [<span class="ps-2 navbar-brand text-white">Manage Project - ]+par_cProjectName+[</span>]
//     l_cHtml += [</div>]
// l_cHtml += [</nav>]

l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Configure Project: ]+par_cProjectName+[</span></div>]
l_cHtml +=    [<div class="px-3 py-2 align-middle ms-auto"><a class="btn btn-primary rounded" href="]+l_cSitePath+[Projects/">Other Projects</a></div>]
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<ul class="nav nav-tabs">]
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cProjectElement == "SETTINGS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Projects/ProjectSettings/]+par_cURLProjectLinkUID+[/">Project Settings</a>]
        l_cHtml += [</li>]
    endif
l_cHtml += [</ul>]

l_cHtml += [<div class="m-3"></div>]  // Spacer

return l_cHtml
//=================================================================================================================                      
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ProjectListFormBuild()
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfProjects
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("ProjectListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("be95fd34-cf27-4c9a-9f59-195f5f3f6bc1","Project")
    :Column("Project.pk"         ,"pk")
    :Column("Project.Name"       ,"Project_Name")
    :Column("Project.LinkUID"    ,"Project_LinkUID")
    :Column("Project.UseStatus"  ,"Project_UseStatus")
    :Column("Project.Description","Project_Description")
    :Column("Upper(Project.Name)","tag1")
    :OrderBy("tag1")

    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
        :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    endif

    :SQL("ListOfProjects")
    l_nNumberOfProjects := :Tally
endwith


if l_nNumberOfProjects > 0
    with object l_oDB2
        :Table("edc19c4c-8d92-46ea-9754-29475478fe2f","Project")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Project.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("CustomField.UsedOn = ^",USEDON_PROJECT)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("94597e1e-1f50-49da-84a3-4799728b8a78","Project")
        :Column("Project.pk"              ,"fk_entity")
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.Label"           ,"CustomField_Label")
        :Column("CustomField.Type"            ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI"     ,"CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM"     ,"CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD"     ,"CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)" ,"tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Project.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("CustomField.UsedOn = ^",USEDON_PROJECT)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith
endif

l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfProjects)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Project on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"3","4")+[">Projects (]+Trans(l_nNumberOfProjects)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name/Manage</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfProjects
                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Projects/ProjectSettings/]+AllTrim(ListOfProjects->Project_LinkUID)+[/">]+Allt(ListOfProjects->Project_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfProjects->Project_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfProjects->Project_UseStatus,1,6),ListOfProjects->Project_UseStatus,1)]
                        l_cHtml += [</td>]

                        if l_nNumberOfCustomFieldValues > 0
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += CustomFieldsBuildGridOther(ListOfProjects->pk,l_hOptionValueToDescriptionMapping)
                            l_cHtml += [</td>]
                        endif

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
static function ProjectEditFormBuild(par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText      := hb_DefaultValue(par_cErrorText,"")

local l_cName                         := hb_HGetDef(par_hValues,"Name","")
local l_nUseStatus                    := hb_HGetDef(par_hValues,"UseStatus",1)
local l_cDescription                  := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_cAlternateNameForModel        := nvl(hb_HGetDef(par_hValues,"AlternateNameForModel"       ,""),"")
local l_cAlternateNameForModels       := nvl(hb_HGetDef(par_hValues,"AlternateNameForModels"      ,""),"")
local l_cAlternateNameForEntity       := nvl(hb_HGetDef(par_hValues,"AlternateNameForEntity"      ,""),"")
local l_cAlternateNameForEntities     := nvl(hb_HGetDef(par_hValues,"AlternateNameForEntities"    ,""),"")
local l_cAlternateNameForAssociation  := nvl(hb_HGetDef(par_hValues,"AlternateNameForAssociation" ,""),"")
local l_cAlternateNameForAssociations := nvl(hb_HGetDef(par_hValues,"AlternateNameForAssociations",""),"")
local l_cAlternateNameForAttribute    := nvl(hb_HGetDef(par_hValues,"AlternateNameForAttribute"   ,""),"")
local l_cAlternateNameForAttributes   := nvl(hb_HGetDef(par_hValues,"AlternateNameForAttributes"  ,""),"")
local l_cAlternateNameForDataType     := nvl(hb_HGetDef(par_hValues,"AlternateNameForDataType"    ,""),"")
local l_cAlternateNameForDataTypes    := nvl(hb_HGetDef(par_hValues,"AlternateNameForDataTypes"   ,""),"")
local l_cAlternateNameForPackage      := nvl(hb_HGetDef(par_hValues,"AlternateNameForPackage"     ,""),"")
local l_cAlternateNameForPackages     := nvl(hb_HGetDef(par_hValues,"AlternateNameForPackages"    ,""),"")

oFcgi:TraceAdd("ProjectEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if empty(par_iPk)
            l_cHtml += [<span class="navbar-brand ms-3">New Project</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update Project Settings</span>]   //navbar-text
        endif
        if oFcgi:p_nAccessLevelML >= 7
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 7
                l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus">]
                    l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                    l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                    l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                    l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]


        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td colspan="2">]
                l_cHtml += [<div class="pb-3">Alternate Name For</div>]
                l_cHtml += [<div class="ps-3">]
                    l_cHtml += [<table>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3"></td>]
                            l_cHtml += [<td class="pb-3">Singular</td>]
                            l_cHtml += [<td class="pb-3">Plural</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Model</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForModel"  id="TextAlternateNameForModel"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForModel) +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForModels" id="TextAlternateNameForModels" value="]+FcgiPrepFieldForValue(l_cAlternateNameForModels)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Entity</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForEntity"   id="TextAlternateNameForEntity"   value="]+FcgiPrepFieldForValue(l_cAlternateNameForEntity)  +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForEntities" id="TextAlternateNameForEntities" value="]+FcgiPrepFieldForValue(l_cAlternateNameForEntities)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Association</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForAssociation"  id="TextAlternateNameForAssociation"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForAssociation) +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForAssociations" id="TextAlternateNameForAssociations" value="]+FcgiPrepFieldForValue(l_cAlternateNameForAssociations)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Attribute</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForAttribute"  id="TextAlternateNameForAttribute"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForAttribute) +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForAttributes" id="TextAlternateNameForAttributes" value="]+FcgiPrepFieldForValue(l_cAlternateNameForAttributes)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Data Type</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForDataType"  id="TextAlternateNameForDataType"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForDataType) +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForDataTypes" id="TextAlternateNameForDataTypes" value="]+FcgiPrepFieldForValue(l_cAlternateNameForDataTypes)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Package</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForPackage"  id="TextAlternateNameForPackage"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForPackage) +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAlternateNameForPackages" id="TextAlternateNameForPackages" value="]+FcgiPrepFieldForValue(l_cAlternateNameForPackages)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                    l_cHtml += [</table>]
                l_cHtml += [</div>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        if !empty(par_iPk)
            l_cHtml += CustomFieldsBuild(par_iPk,USEDON_PROJECT,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))
        endif

    l_cHtml += [</table>]

l_cHtml += [</div>]
 
oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function ProjectEditFormOnSubmit(par_cURLProjectLinkUID)
local l_cHtml := []
local l_cActionOnSubmit

local l_iProjectPk
local l_cProjectName
local l_cProjectLinkUID := par_cURLProjectLinkUID  //It will be overridden in case of add  - Not used for now since only 1 tab
local l_nProjectUseStatus
local l_cProjectDescription

local l_cProjectAlternateNameForModel
local l_cProjectAlternateNameForModels
local l_cProjectAlternateNameForEntity
local l_cProjectAlternateNameForEntities
local l_cProjectAlternateNameForAssociation
local l_cProjectAlternateNameForAssociations
local l_cProjectAlternateNameForAttribute
local l_cProjectAlternateNameForAttributes
local l_cProjectAlternateNameForDataType
local l_cProjectAlternateNameForDataTypes
local l_cProjectAlternateNameForPackage
local l_cProjectAlternateNameForPackages

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1
local l_oDB2

oFcgi:TraceAdd("ProjectEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iProjectPk                           := Val(oFcgi:GetInputValue("TableKey"))
l_cProjectName                         := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_nProjectUseStatus                    := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_cProjectDescription                  := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_cProjectAlternateNameForModel        := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForModel"))
l_cProjectAlternateNameForModels       := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForModels"))
l_cProjectAlternateNameForEntity       := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForEntity"))
l_cProjectAlternateNameForEntities     := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForEntities"))
l_cProjectAlternateNameForAssociation  := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForAssociation"))
l_cProjectAlternateNameForAssociations := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForAssociations"))
l_cProjectAlternateNameForAttribute    := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForAttribute"))
l_cProjectAlternateNameForAttributes   := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForAttributes"))
l_cProjectAlternateNameForDataType     := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForDataType"))
l_cProjectAlternateNameForDataTypes    := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForDataTypes"))
l_cProjectAlternateNameForPackage      := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForPackage"))
l_cProjectAlternateNameForPackages     := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForPackages"))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nUserAccessMode >= 3
        do case
        case empty(l_cProjectName)
            l_cErrorMessage := "Missing Name"
        otherwise
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("b1403658-d289-4af8-b061-a242c93fdfa8","Project")
                :Where([lower(replace(Project.Name,' ','')) = ^],lower(StrTran(l_cProjectName," ","")))
                if l_iProjectPk > 0
                    :Where([Project.pk != ^],l_iProjectPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            else
                //Save the Project
                with object l_oDB1
                    :Table("b953d374-34e6-40d4-9972-df00d392c54a","Project")
                    :Field("Project.Name"                         , l_cProjectName)
                    :Field("Project.UseStatus"                    , l_nProjectUseStatus)
                    :Field("Project.Description"                  , iif(empty(l_cProjectDescription),NULL,l_cProjectDescription))
                    :Field("Project.AlternateNameForModel"        , iif(empty(l_cProjectAlternateNameForModel)       ,NULL,l_cProjectAlternateNameForModel))
                    :Field("Project.AlternateNameForModels"       , iif(empty(l_cProjectAlternateNameForModels)      ,NULL,l_cProjectAlternateNameForModels))
                    :Field("Project.AlternateNameForEntity"       , iif(empty(l_cProjectAlternateNameForEntity)      ,NULL,l_cProjectAlternateNameForEntity))
                    :Field("Project.AlternateNameForEntities"     , iif(empty(l_cProjectAlternateNameForEntities)    ,NULL,l_cProjectAlternateNameForEntities))
                    :Field("Project.AlternateNameForAssociation"  , iif(empty(l_cProjectAlternateNameForAssociation) ,NULL,l_cProjectAlternateNameForAssociation))
                    :Field("Project.AlternateNameForAssociations" , iif(empty(l_cProjectAlternateNameForAssociations),NULL,l_cProjectAlternateNameForAssociations))
                    :Field("Project.AlternateNameForAttribute"    , iif(empty(l_cProjectAlternateNameForAttribute)   ,NULL,l_cProjectAlternateNameForAttribute))
                    :Field("Project.AlternateNameForAttributes"   , iif(empty(l_cProjectAlternateNameForAttributes)  ,NULL,l_cProjectAlternateNameForAttributes))
                    :Field("Project.AlternateNameForDataType"     , iif(empty(l_cProjectAlternateNameForDataType)    ,NULL,l_cProjectAlternateNameForDataType))
                    :Field("Project.AlternateNameForDataTypes"    , iif(empty(l_cProjectAlternateNameForDataTypes)   ,NULL,l_cProjectAlternateNameForDataTypes))
                    :Field("Project.AlternateNameForPackage"      , iif(empty(l_cProjectAlternateNameForPackage)     ,NULL,l_cProjectAlternateNameForPackage))
                    :Field("Project.AlternateNameForPackages"     , iif(empty(l_cProjectAlternateNameForPackages)    ,NULL,l_cProjectAlternateNameForPackages))

                    if empty(l_iProjectPk)
                        l_cProjectLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                        :Field("Project.LinkUID" , l_cProjectLinkUID)
                        if :Add()
                            l_iProjectPk := :Key()
                            // oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Projects/ProjectSettings/"+l_cProjectLinkUID+"/")   // Since there are no other tabs for now, lets go back to the list of Projects
                            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Projects/")
                        else
                            l_cErrorMessage := "Failed to add Project."
                        endif
                    else
                        if :Update(l_iProjectPk)
                            CustomFieldsSave(l_iProjectPk,USEDON_PROJECT,l_iProjectPk)
                            // oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Projects/ProjectSettings/"+l_cProjectLinkUID+"/")   // Since there are no other tabs for now, lets go back to the list of Projects
                            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Projects/")
                        else
                            l_cErrorMessage := "Failed to update Project."
                        endif
                    endif
                endwith
            endif
        endcase
    endif

case l_cActionOnSubmit == "Cancel"
    if empty(l_iProjectPk)
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Projects")
    else
        // oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Projects/ProjectSettings/"+par_cURLProjectLinkUID+"/")   // Since there are no other tabs for now, lets go back to the list of Projects
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Projects/")
    endif

case l_cActionOnSubmit == "Delete"   // Project
    if oFcgi:p_nUserAccessMode >= 3
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

        with object l_oDB1
            :Table("f0d7e892-f938-48b2-9da5-58ac40b1e3e6","Model")
            :Where("Model.fk_Project = ^",l_iProjectPk)
            :SQL()

            if :Tally == 0
                CustomFieldsDelete(l_iProjectPk,USEDON_PROJECT,l_iProjectPk)
                :Delete("853346d3-ece1-4f23-b189-5c70e37a9c6a","Project",l_iProjectPk)

                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Projects/")
            else
                l_cErrorMessage := "Related Model record on file"
            endif
        endwith
    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["Name"]                         := l_cProjectName
    l_hValues["UseStatus"]                    := l_nProjectUseStatus
    l_hValues["Description"]                  := l_cProjectDescription
    l_hValues["AlternateNameForModel"]        := l_cProjectAlternateNameForModel
    l_hValues["AlternateNameForModels"]       := l_cProjectAlternateNameForModels
    l_hValues["AlternateNameForEntity"]       := l_cProjectAlternateNameForEntity
    l_hValues["AlternateNameForEntities"]     := l_cProjectAlternateNameForEntities
    l_hValues["AlternateNameForAssociation"]  := l_cProjectAlternateNameForAssociation
    l_hValues["AlternateNameForAssociations"] := l_cProjectAlternateNameForAssociations
    l_hValues["AlternateNameForAttribute"]    := l_cProjectAlternateNameForAttribute
    l_hValues["AlternateNameForAttributes"]   := l_cProjectAlternateNameForAttributes
    l_hValues["AlternateNameForDataType"]     := l_cProjectAlternateNameForDataType
    l_hValues["AlternateNameForDataTypes"]    := l_cProjectAlternateNameForDataTypes
    l_hValues["AlternateNameForPackage"]      := l_cProjectAlternateNameForPackage
    l_hValues["AlternateNameForPackages"]     := l_cProjectAlternateNameForPackages

    CustomFieldsFormToHash(l_iProjectPk,USEDON_PROJECT,@l_hValues)

    l_cHtml += ProjectEditFormBuild(l_cErrorMessage,l_iProjectPk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
