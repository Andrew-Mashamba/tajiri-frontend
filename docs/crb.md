#CRB Credentials
CRB_PASSWORD=zuit1uausTI
CRB_USERNAME=isale
STRATEGY_ID=2e1a9e93-0489-40e7-8fc2-185a21ae171a
CRB_ENDPOINT=https://idm-stage.creditinfo.co.tz/Web/MultiConnector.svc
CRB_SOAP_ACTION=http://creditinfo.com/schemas/2012/09/MultiConnector/MultiConnectorService/Query


REQUEST
    private function generateXmlPayload(string $clientFirstName, string $clientSurname, string $clientName, string $idNumber, string $birthday, string $phoneNumber, string $idNumberType, string $strategyId, string $idmUsername, string $idmPassword): string
    {
        $uuid = Str::uuid();
        return '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:mul="http://creditinfo.com/schemas/2012/09/MultiConnector" xmlns:req="http://creditinfo.com/schemas/2012/09/MultiConnector/Messages/Request">
   <soapenv:Header>
      <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
         <wsse:UsernameToken wsu:Id="UsernameToken-1" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
            <wsse:Username>' . $idmUsername . '</wsse:Username>
            <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">' . $idmPassword . '</wsse:Password>
         </wsse:UsernameToken>
      </wsse:Security>
   </soapenv:Header>
   <soapenv:Body>
      <mul:Query>
         <mul:request>
            <mul:MessageId>' . $uuid . '</mul:MessageId>
            <mul:RequestXml>
               <mul:RequestXml>
                  <req:connector id="1C8F01F8-71A2-4C99-98A1-8BD1D85C4F63">
                     <req:data id="' . $uuid . '">
                        <request xmlns="http://creditinfo.com/schemas/2012/09/MultiConnector/Connectors/INT/IdmStrategy/Request">
                           <Strategy>
                              <Id>' . $strategyId . '</Id>
                           </Strategy>
                           <ConnectorRequest>
                              <query>
                                 <DateOfBirth>' . $birthday . '</DateOfBirth>
                                 <FirstName>' . $clientFirstName . '</FirstName>
                                 <FullName>' . $clientName . '</FullName>
                                 <IdNumbers>
                                    <IdNumberPairIndividual>
                                       <IdNumber>' . $idNumber . '</IdNumber>
                                       <IdNumberType>' . $idNumberType . '</IdNumberType>
                                    </IdNumberPairIndividual>
                                 </IdNumbers>
                                 <PhoneNumbers>
                                    <string></string>
                                 </PhoneNumbers>
                                 <PresentSurname></PresentSurname>
                              </query>
                           </ConnectorRequest>
                           <Consent>true</Consent>
                        </request>
                     </req:data>
                  </req:connector>
               </mul:RequestXml>
            </mul:RequestXml>
         </mul:request>
      </mul:Query>
   </soapenv:Body>
</soapenv:Envelope>
        ';

    }



RESPONSE

{
  "response": {
    "status": "ok",
    "Extract": {
      "Age": "37",
      "Date": "2025-07-12T15:08:29.3365293Z",
      "APD1DPD": "0",
      "CIPGrade": "XX",
      "CIPScore": "999",
      "Decision": "Approve",
      "CST1Value": "37",
      "CST2Value": "0",
      "CST3Value": "0",
      "INQ2Value": "1",
      "RSK6Value": "0",
      "SCR2Value": "999",
      "CST1Result": "NotEvaluated",
      "CST2Result": "NotEvaluated",
      "CST3Result": "NotEvaluated",
      "INQ2Result": "NotEvaluated",
      "NationalId": "19880209-23613-00001-18",
      "RSK3Result": "NotEvaluated",
      "RSK4Result": "NotEvaluated",
      "RSK6Result": "NotEvaluated",
      "RSK7Result": "NotEvaluated",
      "SCR2Result": "NotEvaluated",
      "SCR4Result": "NotEvaluated",
      "AllContacts": "255762516904",
      "CST12Result": "NotEvaluated",
      "DateOfBirth": "1988-02-08T21:00:00Z",
      "MobileGrade": "E3",
      "MobilePhone": [],
      "MobileScore": "250",
      "RSK10Result": "NotEvaluated",
      "CST1Parameter": "23",
      "CST2Parameter": "1000",
      "CST3Parameter": "700000",
      "INQ2Parameter": "5",
      "RSK3Parameter": "2",
      "RSK4Parameter": "1",
      "RSK6Parameter": "3",
      "RSK7Parameter": "1.1",
      "SCR2Parameter": "530",
      "SCR4Parameter": "548",
      "MobileTotalBalance": "0"
    },
    "infomsg": "ReportGenerated",
    "Currency": "TZS",
    "Strategy": {
      "Id": "2e1a9e93-0489-40e7-8fc2-185a21ae171a",
      "Name": "CIT-TEST_Basic Strategy",
      "BeeStrategy": "Z_MobileLoanStrategy",
      "TemplateName": "TZA_IDM",
      "ReturnOutputDataInSteps": "false"
    },
    "hitcount": "1",
    "PolicyRules": {
      "Rule": [
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK1"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK2"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK3"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK4"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK5"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK6"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK7"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK8"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK9"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK10"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "RSK11"
          },
          "Description": "Rule is disabled. "
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "CST1"
          },
          "Description": "Rule is disabled."
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "CST2"
          },
          "Description": "Rule is disabled."
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "CST3"
          },
          "Description": "Rule is disabled."
        },
        {
          "Result": "NotEvaluated",
          "@attributes": {
            "id": "CST12"
          },
          "Description": "Rule is disabled."
        }
      ]
    },
    "TzaCb5_data": {
      "CIP": {
        "RecordList": {
          "Record": [
            {
              "Date": "2025-07-12T15:08:28.0485101Z",
              "Grade": "XX",
              "Score": "999",
              "Trend": "NoChange",
              "ReasonsList": {
                "Reason": {
                  "Code": "XDAT",
                  "Description": "Subject did not have any snapshots in last 36 months"
                }
              },
              "ProbabilityOfDefault": "100"
            },
            {
              "Date": "2025-06-29T21:00:00Z",
              "Grade": "XX",
              "Score": "999",
              "Trend": "Up",
              "ReasonsList": {
                "Reason": {
                  "Code": "XDAT"
                }
              },
              "ProbabilityOfDefault": "100"
            },
            {
              "Date": "2025-05-30T21:00:00Z",
              "Grade": "D1",
              "Score": "596",
              "Trend": "Up",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  },
                  {
                    "Code": "MSM4"
                  }
                ]
              },
              "ProbabilityOfDefault": "17.87"
            },
            {
              "Date": "2025-04-29T21:00:00Z",
              "Grade": "D2",
              "Score": "576",
              "Trend": "NoChange",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "MSM3"
                  },
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  }
                ]
              },
              "ProbabilityOfDefault": "25.68"
            },
            {
              "Date": "2025-03-30T21:00:00Z",
              "Grade": "D2",
              "Score": "576",
              "Trend": "NoChange",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "MSM3"
                  },
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  }
                ]
              },
              "ProbabilityOfDefault": "25.68"
            },
            {
              "Date": "2025-02-27T21:00:00Z",
              "Grade": "D2",
              "Score": "576",
              "Trend": "NoChange",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "MSM3"
                  },
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  }
                ]
              },
              "ProbabilityOfDefault": "25.68"
            },
            {
              "Date": "2025-01-30T21:00:00Z",
              "Grade": "D2",
              "Score": "576",
              "Trend": "NoChange",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "MSM3"
                  },
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  }
                ]
              },
              "ProbabilityOfDefault": "25.68"
            },
            {
              "Date": "2024-12-30T21:00:00Z",
              "Grade": "D2",
              "Score": "576",
              "Trend": "NoChange",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "MSM3"
                  },
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  }
                ]
              },
              "ProbabilityOfDefault": "25.68"
            },
            {
              "Date": "2024-11-29T21:00:00Z",
              "Grade": "D2",
              "Score": "576",
              "Trend": "NoChange",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "MSM3"
                  },
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  }
                ]
              },
              "ProbabilityOfDefault": "25.68"
            },
            {
              "Date": "2024-10-30T21:00:00Z",
              "Grade": "D2",
              "Score": "576",
              "Trend": "NoChange",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "MSM3"
                  },
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  }
                ]
              },
              "ProbabilityOfDefault": "25.68"
            },
            {
              "Date": "2024-09-29T21:00:00Z",
              "Grade": "D2",
              "Score": "576",
              "Trend": "NoChange",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "MSM3"
                  },
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  }
                ]
              },
              "ProbabilityOfDefault": "25.68"
            },
            {
              "Date": "2024-08-30T21:00:00Z",
              "Grade": "D2",
              "Score": "576",
              "Trend": "NoChange",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "MSM3"
                  },
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  }
                ]
              },
              "ProbabilityOfDefault": "25.68"
            },
            {
              "Date": "2024-07-30T21:00:00Z",
              "Grade": "D2",
              "Score": "576",
              "Trend": "Up",
              "ReasonsList": {
                "Reason": [
                  {
                    "Code": "MSM3"
                  },
                  {
                    "Code": "ATL1"
                  },
                  {
                    "Code": "SND2"
                  }
                ]
              },
              "ProbabilityOfDefault": "25.68"
            }
          ]
        }
      },
      "CIQ": {
        "Detail": {
          "LostStolenRecordsFound": "0",
          "NumberOfCancelledClosedContracts": "0",
          "NumberOfSubscribersMadeInquiriesLast2Days": "1",
          "NumberOfSubscribersMadeInquiriesLast14Days": "1"
        },
        "Summary": {
          "NumberOfFraudAlertsThirdParty": "0",
          "NumberOfFraudAlertsPrimarySubject": "0"
        }
      },
      "Branches": {
        "NumberOfBranches": "0"
      },
      "Disputes": {
        "Summary": {
          "NumberOfFalseDisputes": "0",
          "NumberOfActiveDisputesInCourt": "0",
          "NumberOfActiveDisputesContracts": "0",
          "NumberOfClosedDisputesContracts": "0",
          "NumberOfActiveDisputesSubjectData": "0",
          "NumberOfClosedDisputesSubjectData": "0"
        }
      },
      "Managers": {
        "NumberOfManagers": "0"
      },
      "Contracts": {
        "ContractList": {
          "Contract": [
            {
              "Disputes": {
                "FalseDisputes": "0",
                "ClosedDisputes": "0"
              },
              "StartDate": "2020-03-08T21:00:00Z",
              "Subscriber": "CBA Mpawa",
              "PastDueDays": "784",
              "TotalAmount": {
                "Value": "23199.25",
                "Currency": "TZS",
                "LocalValue": "23199.25"
              },
              "RoleOfClient": "MainDebtor",
              "PastDueAmount": {
                "Value": "23199.25",
                "Currency": "TZS",
                "LocalValue": "23199.25"
              },
              "ContractStatus": "GrantedAndActivated",
              "SubscriberType": "Others",
              "TypeOfContract": "NotSpecified",
              "ContractSubtype": "NotSpecified",
              "ExpectedEndDate": "2020-04-06T21:00:00Z",
              "MethodOfPayment": "NotSpecified",
              "PhaseOfContract": "Open",
              "CurrencyOfContract": "TZS",
              "PaymentPeriodicity": "Irregular",
              "PurposeOfFinancing": "NotSpecified",
              "WorstPastDueAmount": {
                "Value": "23199.25",
                "Currency": "TZS",
                "LocalValue": "23199.25"
              },
              "PaymentCalendarList": {
                "CalendarItem": [
                  {
                    "Date": "2025-07-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-06-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-05-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-04-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-03-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-02-27T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-01-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-12-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-11-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-10-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-09-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-08-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-07-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-06-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-05-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-04-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-03-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-02-28T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-01-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-12-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-11-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-10-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-09-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-08-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-07-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-06-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-05-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-04-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-03-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-02-27T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-01-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2022-12-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2022-11-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2022-10-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2022-09-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2022-08-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  }
                ]
              },
              "NumberOfDueInstallments": "0",
              "NegativeStatusOfContract": "IncreasedRisk"
            },
            {
              "Disputes": {
                "FalseDisputes": "0",
                "ClosedDisputes": "0"
              },
              "StartDate": "2019-07-21T21:00:00Z",
              "Subscriber": "CBA",
              "PastDueDays": "1",
              "TotalAmount": {
                "Value": "29495.00",
                "Currency": "TZS",
                "LocalValue": "29495.00"
              },
              "RoleOfClient": "MainDebtor",
              "PastDueAmount": {
                "Value": "33000.00",
                "Currency": "TZS",
                "LocalValue": "33000.00"
              },
              "ContractStatus": "GrantedAndActivated",
              "SubscriberType": "Banks",
              "TypeOfContract": "Installment",
              "ContractSubtype": "NotSpecified",
              "ExpectedEndDate": "2019-08-20T21:00:00Z",
              "MethodOfPayment": "NotSpecified",
              "PhaseOfContract": "Open",
              "CurrencyOfContract": "TZS",
              "PaymentPeriodicity": "Irregular",
              "PurposeOfFinancing": "NotSpecified",
              "WorstPastDueAmount": {
                "Value": "33000.00",
                "Currency": "TZS",
                "LocalValue": "33000.00"
              },
              "PaymentCalendarList": {
                "CalendarItem": [
                  {
                    "Date": "2025-07-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-06-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-05-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-04-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-03-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-02-27T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2025-01-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-12-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-11-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-10-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-09-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-08-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-07-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-06-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-05-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-04-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-03-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-02-28T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2024-01-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-12-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-11-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-10-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-09-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-08-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-07-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-06-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-05-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-04-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-03-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-02-27T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2023-01-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2022-12-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2022-11-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2022-10-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2022-09-29T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  },
                  {
                    "Date": "2022-08-30T21:00:00Z",
                    "DelinquencyStatus": "NotAvailable"
                  }
                ]
              },
              "NumberOfDueInstallments": "0",
              "NegativeStatusOfContract": "IncreasedRisk"
            }
          ]
        }
      },
      "Dashboard": {
        "CIP": {
          "Grade": "XX",
          "Score": "999"
        },
        "CIQ": {
          "FraudAlerts": "0",
          "FraudAlertsThirdParty": "0"
        },
        "Disputes": {
          "FalseDisputes": "0",
          "ActiveSubjectDisputes": "0",
          "ClosedSubjectDisputes": "0",
          "ActiveContractDisputes": "0",
          "ClosedContractDisputes": "0"
        },
        "Inquiries": {
          "InquiriesForLast12Months": "6"
        },
        "Relations": {
          "NumberOfRelations": "0",
          "NumberOfInvolvements": "0"
        },
        "Collaterals": {
          "NumberOfCollaterals": "0",
          "TotalCollateralValue": {
            "Value": "0",
            "Currency": "TZS",
            "LocalValue": "0"
          },
          "HighestCollateralValue": {
            "Value": "0",
            "Currency": "TZS",
            "LocalValue": "0"
          },
          "HighestCollateralValueType": "NotSpecified"
        },
        "PaymentsProfile": {
          "PastDueAmountSum": {
            "Value": "56199.25",
            "Currency": "TZS",
            "LocalValue": "56199.25"
          },
          "WorstPastDueDaysCurrent": "784",
          "NumberOfDifferentSubscribers": "2",
          "WorstPastDueDaysForLast12Months": "0"
        }
      },
      "Inquiries": {
        "Summary": {
          "NumberOfInquiriesLast1Month": "6",
          "NumberOfInquiriesLast3Months": "6",
          "NumberOfInquiriesLast6Months": "6",
          "NumberOfInquiriesLast12Months": "6",
          "NumberOfInquiriesLast24Months": "6"
        },
        "InquiryList": {
          "Inquiry": [
            {
              "Reason": "ApplicationForCreditOrAmendmentOfCreditTerms",
              "Sector": "Banks",
              "Product": "WS Creditinfo Report Plus",
              "Subscriber": "Diamond Trust Bank",
              "DateOfInquiry": "2025-07-12T09:27:30.513Z"
            },
            {
              "Reason": "ApplicationForCreditOrAmendmentOfCreditTerms",
              "Sector": "Banks",
              "Product": "WS Creditinfo Report Plus",
              "Subscriber": "Diamond Trust Bank",
              "DateOfInquiry": "2025-07-02T00:19:03.73Z"
            },
            {
              "Reason": "ApplicationForCreditOrAmendmentOfCreditTerms",
              "Sector": "Banks",
              "Product": "WS Creditinfo Report Plus",
              "Subscriber": "Diamond Trust Bank",
              "DateOfInquiry": "2025-07-01T23:49:00.813Z"
            },
            {
              "Reason": "ApplicationForCreditOrAmendmentOfCreditTerms",
              "Sector": "Banks",
              "Product": "WS Creditinfo Report Plus",
              "Subscriber": "Diamond Trust Bank",
              "DateOfInquiry": "2025-06-25T11:23:04.817Z"
            },
            {
              "Reason": "ApplicationForCreditOrAmendmentOfCreditTerms",
              "Sector": "Banks",
              "Product": "WS Creditinfo Report Plus",
              "Subscriber": "Diamond Trust Bank",
              "DateOfInquiry": "2025-06-21T11:00:57.68Z"
            }
          ]
        }
      },
      "Individual": {
        "Contact": {
          "MobilePhone": "+255762516904"
        },
        "General": {
          "Gender": "NotSpecified",
          "FullName": "APOLONIA  DEOGRATIAS",
          "Education": "NotSpecified",
          "FirstName": "APOLONIA",
          "Employment": "NotSpecified",
          "Citizenship": "NotSpecified",
          "DateOfBirth": "1988-02-08T21:00:00Z",
          "Nationality": "TZ",
          "BirthSurname": "DEOGRATIAS",
          "MaritalStatus": "NotSpecified",
          "CountryOfBirth": "NotSpecified",
          "NegativeStatus": "NotSpecified",
          "ClassificationOfIndividual": "Individual"
        },
        "MainAddress": {
          "Country": "NotSpecified",
          "AddressLine": "Tanzania"
        },
        "Identifications": {
          "VotersID": "T-1005-9066-080-3",
          "NationalID": "19880209-23613-00001-18",
          "PassportIssuerCountry": "NotSpecified"
        },
        "SecondaryAddress": {
          "Country": "NotSpecified"
        }
      },
      "Parameters": {
        "Consent": "true",
        "IDNumber": "10051217",
        "Sections": {
          "string": "CreditinfoReportPlus"
        },
        "ReportDate": "2025-07-12T15:08:28.0485101Z",
        "SubjectType": "Individual",
        "IDNumberType": "CreditinfoId",
        "InquiryReason": "ApplicationForCreditOrAmendmentOfCreditTerms"
      },
      "ReportInfo": {
        "Created": "2025-07-12T15:08:29.1310038Z",
        "Version": "539",
        "Subscriber": "Diamond Trust Bank",
        "RequestedBy": "Salim Said Hemed",
        "ReportStatus": "ReportGenerated",
        "ReferenceNumber": "4401221-10051217"
      },
      "Shareholders": {
        "NumberOfShareholders": "0"
      },
      "BouncedCheques": [],
      "ContractSummary": {
        "Debtor": {
          "OpenContracts": "2",
          "TotalAmountSum": {
            "Value": "52694.25",
            "Currency": "TZS",
            "LocalValue": "52694.25"
          },
          "ClosedContracts": "0",
          "PastDueAmountSum": {
            "Value": "56199.25",
            "Currency": "TZS",
            "LocalValue": "56199.25"
          }
        },
        "Overall": {
          "WorstPastDueDays": "784",
          "WorstPastDueAmount": {
            "Value": "33000.00",
            "Currency": "TZS",
            "LocalValue": "33000.00"
          },
          "LastDelinquency90PlusDays": "2022-05-30T21:00:00Z",
          "MaxDueInstallmentsOpenContracts": "0",
          "MaxDueInstallmentsClosedContracts": "0"
        },
        "Guarantor": {
          "OpenContracts": "0",
          "ClosedContracts": "0"
        },
        "SectorInfoList": {
          "SectorInfo": [
            {
              "Sector": "Others",
              "DebtorOpenContracts": "1",
              "DebtorTotalAmountSum": {
                "Value": "23199.25",
                "Currency": "TZS",
                "LocalValue": "23199.25"
              },
              "DebtorClosedContracts": "0",
              "DebtorPastDueAmountSum": {
                "Value": "23199.25",
                "Currency": "TZS",
                "LocalValue": "23199.25"
              },
              "GuarantorOpenContracts": "0",
              "GuarantorClosedContracts": "0"
            },
            {
              "Sector": "Banks",
              "DebtorOpenContracts": "1",
              "DebtorTotalAmountSum": {
                "Value": "29495.00",
                "Currency": "TZS",
                "LocalValue": "29495.00"
              },
              "DebtorClosedContracts": "0",
              "DebtorPastDueAmountSum": {
                "Value": "33000.00",
                "Currency": "TZS",
                "LocalValue": "33000.00"
              },
              "GuarantorOpenContracts": "0",
              "GuarantorClosedContracts": "0"
            }
          ]
        },
        "PaymentCalendarList": {
          "PaymentCalendar": [
            {
              "Date": "2025-07-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2025-06-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2025-05-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2025-04-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2025-03-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2025-02-27T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2025-01-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-12-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-11-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-10-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-09-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-08-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-07-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-06-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-05-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-04-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-03-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-02-28T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2024-01-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-12-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-11-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-10-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-09-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-08-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-07-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-06-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-05-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-04-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-03-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-02-27T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2023-01-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2022-12-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2022-11-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2022-10-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2022-09-29T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            },
            {
              "Date": "2022-08-30T21:00:00Z",
              "Classification": "NotAvailable",
              "ContractsSubmitted": "0"
            }
          ]
        },
        "AffordabilitySummary": {
          "MonthlyAffordability": {
            "Value": "0",
            "Currency": "TZS",
            "LocalValue": "0"
          }
        },
        "AffordabilityHistoryList": {
          "AffordabilityHistory": [
            {
              "Year": "2025",
              "Month": "7",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2025",
              "Month": "6",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2025",
              "Month": "5",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2025",
              "Month": "4",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2025",
              "Month": "3",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2025",
              "Month": "2",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2025",
              "Month": "1",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2024",
              "Month": "12",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2024",
              "Month": "11",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2024",
              "Month": "10",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2024",
              "Month": "9",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            },
            {
              "Year": "2024",
              "Month": "8",
              "MonthlyAffordability": {
                "Value": "0",
                "Currency": "TZS",
                "LocalValue": "0"
              }
            }
          ]
        }
      },
      "ContractOverview": {
        "ContractList": {
          "Contract": [
            {
              "Sector": "Others",
              "StartDate": "2020-03-08T21:00:00Z",
              "PastDueDays": "784",
              "TotalAmount": {
                "Value": "23199.25",
                "Currency": "TZS",
                "LocalValue": "23199.25"
              },
              "RoleOfClient": "MainDebtor",
              "PastDueAmount": {
                "Value": "23199.25",
                "Currency": "TZS",
                "LocalValue": "23199.25"
              },
              "ContractStatus": "GrantedAndActivated",
              "TypeOfContract": "NotSpecified",
              "PhaseOfContract": "Open"
            },
            {
              "Sector": "Banks",
              "StartDate": "2019-07-21T21:00:00Z",
              "PastDueDays": "1",
              "TotalAmount": {
                "Value": "29495.00",
                "Currency": "TZS",
                "LocalValue": "29495.00"
              },
              "RoleOfClient": "MainDebtor",
              "PastDueAmount": {
                "Value": "33000.00",
                "Currency": "TZS",
                "LocalValue": "33000.00"
              },
              "ContractStatus": "GrantedAndActivated",
              "TypeOfContract": "Installment",
              "PhaseOfContract": "Open"
            }
          ]
        }
      },
      "CurrentRelations": {
        "ContractRelationList": {
          "ContractRelation": {
            "Contact": {
              "MobilePhone": "+255762516904"
            },
            "ValidTo": "2021-12-30T21:00:00Z",
            "FullName": "APOLONIA   DEOGRATIAS",
            "ValidFrom": "2021-10-30T21:00:00Z",
            "MainAddress": {
              "Country": "NotSpecified",
              "AddressLine": "Tanzania",
              "PostalCodeLookup": "NotSpecified"
            },
            "SubjectType": "Individual",
            "CreditinfoId": "0",
            "IDNumberType": "NotSpecified",
            "RoleOfCustomer": "MainDebtor",
            "SecondaryAddress": {
              "Country": "NotSpecified",
              "PostalCodeLookup": "NotSpecified"
            }
          }
        }
      },
      "SubjectInfoHistory": {
        "GeneralList": {
          "General": [
            {
              "Item": "FullName",
              "Value": "APOLONIA  DEOGRATIAS",
              "ValidTo": "2021-10-30T21:00:00Z",
              "ValidFrom": "2021-09-29T21:00:00Z",
              "Subscriber": "B01"
            },
            {
              "Item": "FullName",
              "Value": "APOLONIA   DEOGRATIAS",
              "ValidTo": "2022-03-30T21:00:00Z",
              "ValidFrom": "2021-10-30T21:00:00Z",
              "Subscriber": "B01"
            }
          ]
        }
      },
      "PaymentIncidentList": {
        "Summary": {
          "DueAmountSummary": {
            "Value": "0",
            "Currency": "TZS",
            "LocalValue": "0"
          },
          "OutstandingAmountSummary": {
            "Value": "0",
            "Currency": "TZS",
            "LocalValue": "0"
          }
        }
      }
    },
    "ScoringAnalysis": {
      "CIPScore": "999",
      "Conclusion": [],
      "MobileScore": "250",
      "PolicyRules": {
        "Rule": [
          {
            "Result": "NotEvaluated",
            "@attributes": {
              "id": "SCR1"
            },
            "Description": "Rule is disabled. "
          },
          {
            "Result": "NotEvaluated",
            "@attributes": {
              "id": "SCR2"
            },
            "Description": "Rule is disabled. "
          },
          {
            "Result": "NotEvaluated",
            "@attributes": {
              "id": "SCR3"
            },
            "Description": "Rule is disabled. "
          },
          {
            "Result": "NotEvaluated",
            "@attributes": {
              "id": "SCR4"
            },
            "Description": "Rule is disabled. "
          },
          {
            "Result": "NotEvaluated",
            "@attributes": {
              "id": "SCR5"
            },
            "Description": "Rule is disabled. "
          }
        ]
      },
      "CIPRiskGrade": "XX",
      "MobileScoreRiskGrade": "E3"
    },
    "CurrentContracts": {
      "Total": {
        "Balance": "0",
        "Negative": "2",
        "Positive": "0",
        "BalanceAtRisk": "0"
      },
      "CurrentBanking": {
        "Balance": "0",
        "Negative": "1",
        "Positive": "0",
        "BalanceAtRisk": "0"
      },
      "CurrentNonBanking": {
        "Balance": "0",
        "Negative": "1",
        "Positive": "0",
        "BalanceAtRisk": "0"
      }
    },
    "InquiriesAnalysis": {
      "Conclusion": [],
      "PolicyRules": {
        "Rule": [
          {
            "Result": "NotEvaluated",
            "@attributes": {
              "id": "INQ1"
            },
            "Description": []
          },
          {
            "Result": "NotEvaluated",
            "@attributes": {
              "id": "INQ2"
            },
            "Description": []
          },
          {
            "Result": "NotEvaluated",
            "@attributes": {
              "id": "INQ3"
            },
            "Description": []
          }
        ]
      },
      "TotalLast7Days": "1",
      "TotalLast1Month": "6",
      "NonBankingLast1Month": "0"
    },
    "GeneralInformation": {
      "BrokenRules": "0",
      "RequestDate": "2025-07-11T21:00:00Z",
      "ReferenceNumber": "4401221-10051217",
      "SubjectIDNumber": "19880209-23613-00001-18",
      "RecommendedDecision": "Approve"
    },
    "PastDueInformation": {
      "TotalCurrentPastDue": "56199",
      "WorstCurrentPastDue": "33000.00",
      "TotalCurrentDaysPastDue": "785",
      "WorstCurrentDaysPastDue": "784",
      "WorstPastDueLast12Months": "0",
      "WorstPastDueDaysLast12Months": "0",
      "MonthsWithoutArrearsLast12Months": "0",
      "TotalMonthsWithHistoryLast12Months": "0"
    },
    "PersonalInformation": {
      "Age": "37",
      "Gender": "NotSpecified",
      "FullName": "APOLONIA  DEOGRATIAS",
      "DateOfBirth": "1988-02-08T21:00:00Z",
      "MaritalStatus": "NotSpecified",
      "EmploymentStatus": "NotSpecified"
    },
    "RepaymentInformation": {
      "ClosedContracts": "0",
      "LastContractOpened": "2020-03-09",
      "TotalMonthlyPayment": "0"
    }
  },
  "@attributes": {
    "id": "d90226b1-60aa-4e17-9cea-07e2b14a079d"
  }
}

---

## TAJIRI app — portfolio REST API (summary)

The Flutter client does **not** call Creditinfo SOAP. Use **`auth:sanctum`** JSON routes:

| Method | Path |
|--------|------|
| `GET` | `/api/credit-bureau/active-loans-overview?user_id={profileId}` |
| `POST` | `/api/credit-bureau/active-loans/sync` |

Per-business debt sync remains: `POST /api/business/{businessId}/debts/sync-crb`.

Behaviour, tables (`user_profile_crb_loans`, `user_business_debts.crb_meta`, audits), and alignment with this document’s XML shapes: **`docs/modules/debts_crb_backend_directive.md`**.
