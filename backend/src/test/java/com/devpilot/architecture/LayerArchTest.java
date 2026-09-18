package com.devpilot.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.devpilot.testsupport.UnitTest;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.bind.annotation.RestController;

/**
 * ARCH-04(계층 방향 일부), ARCH-09(컨트롤러 위치·이름), ARCH-20(명명 일부) — docs/08 §11.6.
 * entity·repository·application 서비스 명명 규칙은 해당 클래스가 생기는 S1에 추가한다.
 */
@UnitTest
class LayerArchTest {

    @Test
    void shouldNotLetPresentationDependOnInfrastructure() {
        noClasses()
                .that()
                .resideInAPackage("..presentation..")
                .should()
                .dependOnClassesThat()
                .resideInAPackage("..infrastructure..")
                .because("ARCH-04: controller -> repository is forbidden (docs/03 §2.3)")
                .check(ArchitectureClasses.main());
    }

    @Test
    void shouldNotDependOnPresentationFromOtherLayers() {
        noClasses()
                .that()
                .resideOutsideOfPackage("..presentation..")
                .should()
                .dependOnClassesThat()
                .resideInAPackage("..presentation..")
                .because("ARCH-04: nothing depends on presentation (docs/03 §2.3)")
                .check(ArchitectureClasses.main());
    }

    @Test
    void shouldKeepRestControllersInPresentationWithControllerSuffix() {
        classes()
                .that()
                .areAnnotatedWith(RestController.class)
                .should()
                .resideInAPackage("..presentation..")
                .andShould()
                .haveSimpleNameEndingWith("Controller")
                .because("ARCH-09: docs/08 §6")
                .check(ArchitectureClasses.main());
    }

    @Test
    void shouldNameConfigurationClassesWithConfigSuffix() {
        classes()
                .that()
                .areAnnotatedWith(Configuration.class)
                .should()
                .haveSimpleNameEndingWith("Config")
                .because("ARCH-20: docs/08 §7")
                .check(ArchitectureClasses.main());
    }

    @Test
    void shouldNotUseVagueClassNameSuffixes() {
        noClasses()
                .should()
                .haveSimpleNameEndingWith("Util")
                .orShould()
                .haveSimpleNameEndingWith("Utils")
                .orShould()
                .haveSimpleNameEndingWith("Helper")
                .orShould()
                .haveSimpleNameEndingWith("Manager")
                .orShould()
                .haveSimpleNameEndingWith("Impl")
                .because("ARCH-20: docs/08 §7")
                .check(ArchitectureClasses.main());
    }
}
