// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/SetterGetter.sol";
import "../contracts/facets/EmailSetter.sol";
import "../contracts/facets/SetterAddress.sol";
import "forge-std/Test.sol";
import "../contracts/Diamond.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    SetterGetter setterGetter;
    EmailSetter emailSetter;
    SetterAddress setterAddress;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function testAddFaucet() public {
        setterGetter = new SetterGetter();

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](1);
        cut[0] = (
            FacetCut({
                facetAddress: address(setterGetter),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("SetterGetter")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");
        SetterGetter(address(diamond)).setName("Aji");
        string memory name = SetterGetter(address(diamond)).getName();

        assert(
            keccak256(abi.encodePacked(name)) ==
                keccak256(abi.encodePacked("Aji"))
        ); // Ensure string comparison works

        emailSetter = new EmailSetter();

        // build cut struct
        FacetCut[] memory cut1 = new FacetCut[](1);
        cut1[0] = (
            FacetCut({
                facetAddress: address(emailSetter),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("EmailSetter")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut1, address(0x0), "");
        EmailSetter(address(diamond)).setEmail("Freddy@mail.com");
        string memory email = EmailSetter(address(diamond)).getEmail();

        assert(
            keccak256(abi.encodePacked(email)) ==
                keccak256(abi.encodePacked("Freddy@mail.com"))
        ); // Ensure string comparison works

        SetterGetter(address(diamond)).setAge(20);

        uint8 age = SetterGetter(address(diamond)).getAge();
        assert(
            keccak256(abi.encodePacked(age)) ==
                keccak256(abi.encodePacked(uint8(20)))
        ); // Ensure string comparison works

        setterAddress = new SetterAddress();

        // build cut struct
        FacetCut[] memory cut2 = new FacetCut[](1);
        cut2[0] = (
            FacetCut({
                facetAddress: address(setterAddress),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("SetterAddress")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut2, address(0x0), "");
        SetterAddress(address(diamond)).setAddr("5 Main St");
        string memory addr = SetterAddress(address(diamond)).getAddr();

        assert(
            keccak256(abi.encodePacked(addr)) ==
                keccak256(abi.encodePacked("5 Main St"))
        ); // Ensure string comparison works
    }

    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
