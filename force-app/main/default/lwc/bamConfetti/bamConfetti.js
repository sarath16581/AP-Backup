import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import GlobalAssetsURL from '@salesforce/resourceUrl/GlobalAssets';
import Egg from './egg';

export default class BamConfetti extends LightningElement {
    spreadVal = 50;
    velocityVal = 70;
    particlesVal = 1000;
    xVal = 0.5;
    yVal = 1.0;
    

    checkIfCorrectCombination = e => {
        const ESC_KEY = 27;
        if ((e.which === ESC_KEY || e.keyCode === ESC_KEY)) {
            this.handleCelebration();
        }
    }

    connectedCallback() {
        loadScript(this, GlobalAssetsURL + '/js/canvasConfetti/0.2.1/canvasConfetti.min.js')
        .then(() => {
            // set up listener for easter egg
            let eggsy = new Egg();
            eggsy
            .AddCode("up,up,down,down,left,right,left,right,b,a", this.handleCelebration, "konami-code")
            .Listen()
            //window.addEventListener('keyup', this.checkIfCorrectCombination)
        })
        .catch( error => {
            console.log(error)
        });
    }

    handleCelebration() {
        // eslint-disable-next-line no-undef
        confetti({
            startVelocity: this.velocityVal,
            particleCount: this.particlesVal,
            spread: this.spreadVal,
            origin: {
                y: this.yVal,
                x: this.xVal
            }
        });
    }
}